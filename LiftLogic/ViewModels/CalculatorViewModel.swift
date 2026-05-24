import Foundation
import Observation

@Observable
final class CalculatorViewModel {
    var inputString: String = ""
    var currentMode: AppMode = .calc
    var selectedBar: BarType = .olympic45lb
    var collarType: CollarType = .none
    var isSingleSided: Bool = false
    var reversePlateStack: [LoadedPlate] = []
    var oneRMReps: Int = 5
    private(set) var capturedWeight: Double = 0

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
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
        let current = targetWeight
        let newValue = current + step
        inputString = formatWeight(newValue)
    }

    func decrement() {
        let step = smallestEnabledPlate * 2
        let current = targetWeight
        let newValue = max(0, current - step)
        inputString = newValue == 0 ? "" : formatWeight(newValue)
    }

    func loadWeight(_ value: Double) {
        capturedWeight = 0
        inputString = formatWeight(value)
    }

    func commitWeight() {
        guard targetWeight > 0 else { return }
        settings.addRecentWeight(targetWeight)
        settings.successfulCalculationCount += 1
    }

    // MARK: — Reverse mode

    func addPlate(_ plate: PlateInventoryItem) {
        reversePlateStack.append(LoadedPlate(weight: plate.weight))
    }

    func undoLastPlate() {
        guard !reversePlateStack.isEmpty else { return }
        reversePlateStack.removeLast()
    }

    func clearReverseStack() {
        reversePlateStack.removeAll()
    }

    // MARK: — Helpers

    private func formatWeight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.2f", value)
    }
}
