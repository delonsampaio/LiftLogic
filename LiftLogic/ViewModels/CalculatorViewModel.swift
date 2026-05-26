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
    private(set) var capturedWeight: Double = 0

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

    var deltaResult: PlateResult? {
        guard capturedWeight > 0, targetWeight > 0,
              abs(targetWeight - capturedWeight) > 0.001 else { return nil }
        return CalculatorEngine.calculate(
            target: abs(targetWeight - capturedWeight),
            barWeight: 0,
            collarWeight: 0,
            inventory: settings.activeInventory,
            unit: settings.unit,
            isSingleSided: isSingleSided
        )
    }

    var isDeltaAdding: Bool { targetWeight > capturedWeight }

    var smallestEnabledPlate: Double {
        settings.activeInventory
            .filter(\.isEnabled)
            .map(\.weight)
            .min() ?? 2.5
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
        if targetWeight > 0 { capturedWeight = targetWeight }
        inputString = ""
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
        capturedWeight = 0
        inputString = value.weightStringPrecise
        commitWeight()
    }

    /// Records the current weight to recent history. Ignored if below the bar weight
    /// (filters out keystroke pollution like "1" while typing "125").
    func commitWeight() {
        guard targetWeight >= resolvedBarWeight, targetWeight > 0 else { return }
        settings.addRecentWeight(targetWeight)
        settings.successfulCalculationCount += 1
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

    /// True if the user has hit an inventory limit and tried to add more.
    var reverseHitInventoryLimit: Bool {
        hasReverseInventoryLimits &&
        settings.activeInventory.contains { plate in
            plate.isEnabled && reverseCount(for: plate.weight) >= reverseMaxPerSide(for: plate) && plate.quantity != Int.max
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

    func clearReverseStack() {
        reversePlateStack.removeAll()
    }
}
