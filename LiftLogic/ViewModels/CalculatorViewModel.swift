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
            isSingleSided: isSingleSided
        )
    }

    var oneRMResult: OneRMResult {
        OneRMEngine.calculate(weight: targetWeight, reps: oneRMReps)
    }

    var reverseTotal: Double {
        let platesTotal = reversePlateStack.map(\.weight).reduce(0, +)
        let sides: Double = isSingleSided ? 1 : 2
        return resolvedBarWeight + resolvedCollarWeight + (platesTotal * sides)
    }

    var smallestEnabledPlate: Double {
        settings.activeInventory
            .filter(\.isEnabled)
            .map(\.weight)
            .min() ?? 2.5
    }

    // MARK: — Delta (Add / Remove per side)

    /// Snapshot of the plate result the user last confirmed as loaded.
    /// Used to compute the add/remove delta when the target changes.
    private(set) var committedResult: PlateResult? = nil

    /// Per-side plate changes between `committedResult` and the current target.
    /// Positive count = add that plate, negative = remove.
    /// Empty when there is nothing committed yet or current matches committed.
    var plateDelta: [(weight: Double, change: Int)] {
        guard let committed = committedResult else { return [] }
        let current = plateResult
        // Only show delta when current weight resolves to a real plate setup.
        guard !current.platesPerSide.isEmpty else { return [] }

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

    func appendDigit(_ digit: String) {
        if digit == "." && inputString.contains(".") { return }
        if inputString == "0" && digit != "." { inputString = digit; return }
        inputString.append(contentsOf: digit)
    }

    func deleteLastDigit() {
        guard !inputString.isEmpty else { return }
        inputString.removeLast()
    }

    func resetWeight() {
        inputString = ""
        committedResult = nil   // clear delta when bar is wiped
    }

    func increment() {
        let step = smallestEnabledPlate * 2
        let newValue = targetWeight + step
        inputString = newValue.weightStringPrecise
        commitWeight()
    }

    func decrement() {
        let step = smallestEnabledPlate * 2
        let newValue = max(0, targetWeight - step)
        inputString = newValue == 0 ? "" : newValue.weightStringPrecise
        commitWeight()
    }

    func loadWeight(_ value: Double) {
        inputString = value.weightStringPrecise
        commitWeight()
    }

    /// Records the current weight to recent history and snapshots the plate result
    /// so the delta banner can show what changed on the next edit.
    /// Ignored if below the bar weight (filters out keystroke pollution).
    func commitWeight() {
        guard targetWeight >= resolvedBarWeight, targetWeight > 0 else { return }
        settings.addRecentWeight(targetWeight)
        settings.successfulCalculationCount += 1
        committedResult = plateResult   // snapshot for delta comparison
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
        return reverseCount(for: plate.weight) < max
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
