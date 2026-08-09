import Foundation
import Observation

@Observable
final class CalculatorViewModel {
    var inputString: String = ""
    var currentMode: AppMode = .calc
    var selectedBar: BarType
    var collarType: CollarType = .none
    var isSingleSided: Bool = false
    var reversePlateStack: [LoadedPlate] = []
    var oneRMReps: Int = 5
    var oneRMRPE: Double = 10.0
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        self.selectedBar = settings.defaultBar
    }

    // MARK: — Derived

    var targetWeight: Double {
        Double(inputString) ?? 0
    }

    var resolvedBarWeight: Double {
        selectedBar == .custom
            ? settings.customBarWeight
            : selectedBar.weight(in: settings.unit)
    }

    var resolvedCollarWeight: Double {
        collarType.totalWeight(in: settings.unit)
    }

    var plateResult: PlateResult {
        CalculatorEngine.calculate(
            target: targetWeight,
            barWeight: resolvedBarWeight,
            collarWeight: resolvedCollarWeight,
            inventory: settings.activeInventory,
            unit: settings.unit,
            isSingleSided: isSingleSided
        )
    }

    var warmupSets: [WarmupSet] {
        WarmupEngine.calculate(
            target: targetWeight,
            barWeight: resolvedBarWeight,
            collarWeight: resolvedCollarWeight,
            inventory: settings.activeInventory,
            unit: settings.unit,
            isSingleSided: isSingleSided,
            percentages: settings.warmupPercentages.map(\.percentage)
        )
    }

    var oneRMResult: OneRMResult {
        OneRMEngine.calculate(weight: targetWeight, reps: oneRMReps)
    }

    var rpeAdjustedOneRM: Double? {
        guard let percent = OneRMEngine.percentOf1RM(reps: oneRMReps, rpe: oneRMRPE) else { return nil }
        return targetWeight / (percent / 100)
    }

    func relativeStrengthResult(bodyweightKg: Double, sex: Sex, liftedKg: Double) -> RelativeStrengthResult {
        RelativeStrengthEngine.calculate(bodyweightKg: bodyweightKg, sex: sex, liftedKg: liftedKg)
    }

    var reverseTotal: Double {
        let platesTotal = reversePlateStack.map(\.weight).reduce(0, +)
        let sides: Double = isSingleSided ? 1 : 2
        return resolvedBarWeight + resolvedCollarWeight + (platesTotal * sides)
    }

    /// Plate grouping to display for the current mode: the reverse stack in REV
    /// mode, otherwise the computed CALC result. Keeps the share card consistent
    /// with what the user is actually looking at.
    var displayGrouped: [(weight: Double, count: Int)] {
        if currentMode == .reverse {
            return PlateResult(platesPerSide: reversePlateStack, totalWeight: reverseTotal, remainder: 0).grouped
        }
        return plateResult.grouped
    }

    /// Total weight the loaded bar falls short of the target (0 when exact).
    /// `plateResult.remainder` is a *per-side* value, so a two-sided bar is short
    /// on both sides — the total shortfall is doubled unless loading single-sided.
    var totalShort: Double {
        guard !plateResult.isExact else { return 0 }
        return plateResult.remainder * (isSingleSided ? 1 : 2)
    }

    /// Closest total weight actually loadable at or below the target.
    var closestLoadableWeight: Double {
        max(0, targetWeight - totalShort)
    }

    var smallestEnabledPlate: Double {
        settings.activeInventory
            .filter(\.isEnabled)
            .map(\.weight)
            .min() ?? 2.5
    }

    var maxInputWeight: Double {
        settings.unit == .lbs ? 2000 : 907
    }

    // MARK: — Delta (Add / Remove per side)

    /// Snapshot of the plate result last settled on (advances every debounce fire).
    private(set) var committedResult: PlateResult? = nil

    /// The delta captured at the last debounce fire, shown by the toast.
    /// Stable between fires so the toast doesn't flicker mid-keystroke.
    private(set) var lastDelta: [(weight: Double, change: Int)] = []

    /// Live per-side diff between committedResult and the current target.
    /// Used internally to compute lastDelta before advancing committedResult.
    private var plateDelta: [(weight: Double, change: Int)] {
        guard let committed = committedResult else { return [] }
        let current = plateResult

        var committedCounts: [Double: Int] = [:]
        for plate in committed.platesPerSide {
            committedCounts[plate.weight, default: 0] += 1
        }
        var currentCounts: [Double: Int] = [:]
        for plate in current.platesPerSide {
            currentCounts[plate.weight, default: 0] += 1
        }

        let allWeights = Set(committedCounts.keys).union(currentCounts.keys)
        return allWeights
            .compactMap { weight -> (Double, Int)? in
                let diff = (currentCounts[weight] ?? 0) - (committedCounts[weight] ?? 0)
                return diff != 0 ? (weight, diff) : nil
            }
            .sorted { $0.0 > $1.0 }  // heaviest first
    }

    // MARK: — Actions

    // Set to true when the cap clamps input so the next debounce-triggered
    // commitWeight doesn't lock in the clamped value as the delta baseline.
    private var suppressNextCommit = false

    func appendDigit(_ digit: String) {
        if digit == "." && inputString.contains(".") { return }
        if inputString == "0" && digit != "." { inputString = digit; return }
        inputString.append(contentsOf: digit)
        if let value = Double(inputString), value > maxInputWeight {
            inputString = maxInputWeight.weightStringPrecise
            suppressNextCommit = true
        }
    }

    func deleteLastDigit() {
        guard !inputString.isEmpty else { return }
        inputString.removeLast()
    }

    func resetWeight() {
        inputString = ""
        committedResult = nil
        lastDelta = []
    }

    func increment() {
        let step = smallestEnabledPlate * 2
        let newValue = min(targetWeight + step, maxInputWeight)
        inputString = newValue.weightStringPrecise
        commitWeight(suppressDelta: true)   // explicit action — user is loading this, no delta banner
    }

    func decrement() {
        let step = smallestEnabledPlate * 2
        let newValue = max(0, targetWeight - step)
        inputString = newValue == 0 ? "" : newValue.weightStringPrecise
        if newValue == 0 {
            committedResult = nil
            lastDelta = []
        } else {
            commitWeight(suppressDelta: true)
        }
    }

    func loadWeight(_ value: Double) {
        inputString = min(value, maxInputWeight).weightStringPrecise
        commitWeight(suppressDelta: true)   // chip tap = "this is what I'm loading", no delta banner
    }

    /// Increments each time commitWeight() fires — used by CalcModeView to
    /// show the delta toast only after the debounce settles, not mid-keystroke.
    private(set) var commitRevision: Int = 0

    /// Captures the current delta into lastDelta, then advances committedResult
    /// to the current weight. Called by the 1.2 s debounce and explicit actions.
    func commitWeight(suppressDelta: Bool = false) {
        if suppressNextCommit { suppressNextCommit = false; return }
        guard targetWeight >= resolvedBarWeight, targetWeight > 0 else { return }
        applyDecimalPrecisionLockIfNeeded()
        settings.addRecentWeight(targetWeight)
        if settings.isPro {
            settings.recordHistory(weight: targetWeight, barType: selectedBar, collarType: collarType, unit: settings.unit, isSingleSided: isSingleSided)
        }
        settings.successfulCalculationCount += 1
        lastDelta = suppressDelta ? [] : plateDelta   // snapshot diff before advancing baseline (unless caller wants it suppressed)
        committedResult = plateResult   // always advance — keeps baseline current
        commitRevision += 1
    }

    /// Snaps `inputString` to the nearest weight achievable with the currently-enabled
    /// plates, when the Pro Decimal Precision Lock is on. No-op when the lock is off.
    /// Works in both lbs and kg — deliberately reuses the same granularity formula
    /// (`smallestEnabledPlate * 2`) as the +/- quick-increment step, rather than a
    /// hardcoded constant, so it stays correct whether the user has only standard
    /// plates enabled or has turned on micro-loading.
    private func applyDecimalPrecisionLockIfNeeded() {
        guard settings.decimalPrecisionLockEnabled, settings.isPro else { return }
        let granularity = smallestEnabledPlate * 2
        guard granularity > 0 else { return }
        let rounded = (targetWeight / granularity).rounded() * granularity
        if rounded != targetWeight {
            inputString = rounded.weightStringPrecise
        }
    }

    // MARK: — Reverse mode

    /// Per-side count for a given plate weight in the current REV stack.
    func reverseCount(for weight: Double) -> Int {
        reversePlateStack.filter { $0.weight == weight }.count
    }

    /// Maximum plates of this weight the user can add per side based on inventory.
    /// Int.max means no limit set.
    func reverseMaxPerSide(for plate: PlateInventoryItem) -> Int {
        guard plate.quantity != Int.max else { return Int.max }
        return isSingleSided ? plate.quantity : plate.quantity / 2
    }

    func canAddPlate(_ plate: PlateInventoryItem) -> Bool {
        let max = reverseMaxPerSide(for: plate)
        guard reverseCount(for: plate.weight) < max else { return false }
        guard reversePlateStack.count < 11 else { return false }
        let projectedTotal = reverseTotal + plate.weight * (isSingleSided ? 1 : 2)
        return projectedTotal <= maxInputWeight
    }

    /// Whether the user has any quantity limit set on any enabled plate.
    var hasReverseInventoryLimits: Bool {
        settings.activeInventory.contains { $0.isEnabled && $0.quantity != Int.max }
    }

    /// True if at least one plate has hit its inventory limit.
    var reverseHitInventoryLimit: Bool {
        hasReverseInventoryLimits &&
        settings.activeInventory.contains { plate in
            plate.isEnabled && reverseCount(for: plate.weight) >= reverseMaxPerSide(for: plate) && plate.quantity != Int.max
        }
    }

    /// True when every enabled plate with a quantity limit is fully used up (nothing left to add).
    var reverseAllInventoryExhausted: Bool {
        hasReverseInventoryLimits &&
        settings.activeInventory.filter { $0.isEnabled && $0.quantity != Int.max }.allSatisfy { plate in
            reverseCount(for: plate.weight) >= reverseMaxPerSide(for: plate)
        }
    }

    func addPlate(_ plate: PlateInventoryItem) {
        guard canAddPlate(plate) else { return }
        reversePlateStack.append(LoadedPlate(weight: plate.weight))
    }

    func undoLastPlate() {
        guard !reversePlateStack.isEmpty else { return }
        reversePlateStack.removeLast()
    }

    func removePlate(id: UUID) {
        guard let idx = reversePlateStack.lastIndex(where: { $0.id == id }) else { return }
        reversePlateStack.remove(at: idx)
    }

    func clearReverseStack() {
        reversePlateStack.removeAll()
    }
}
