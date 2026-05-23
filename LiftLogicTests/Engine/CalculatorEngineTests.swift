import Testing
@testable import LiftLogic

@Suite("CalculatorEngine")
struct CalculatorEngineTests {

    let lbsInventory: [PlateInventoryItem] = [45, 35, 25, 10, 5, 2.5].map {
        PlateInventoryItem(weight: $0, isEnabled: true)
    }

    @Test func classic225() {
        // 225 lbs, 45 lb bar, no collars → 2× 45 per side
        let result = CalculatorEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        #expect(result.platesPerSide.count == 2)
        #expect(result.platesPerSide.allSatisfy { $0.weight == 45 })
    }

    @Test func remainder() {
        // 228 lbs with no 1 lb plate — should have remainder
        let inv = [45, 25, 10, 5, 2.5].map { PlateInventoryItem(weight: $0, isEnabled: true) }
        let result = CalculatorEngine.calculate(
            target: 228, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(!result.isExact)
        #expect(result.remainder > 0)
    }

    @Test func floatEpsilonKg() {
        // 10 kg loaded as four 2.5 kg plates must not accumulate float drift
        let inv = [PlateInventoryItem(weight: 2.5, isEnabled: true)]
        let result = CalculatorEngine.calculate(
            target: 30, barWeight: 20, collarWeight: 0,
            inventory: inv, unit: .kg, isSingleSided: false
        )
        #expect(result.isExact)
        #expect(result.platesPerSide.count == 2)
    }

    @Test func singleSidedLoadsAllWeight() {
        // landmine: all net weight on one side
        let result = CalculatorEngine.calculate(
            target: 100, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: true
        )
        let totalLoaded = result.platesPerSide.map(\.weight).reduce(0, +)
        #expect(abs(totalLoaded - 55) < 0.01)
    }

    @Test func barHeavierThanTarget() {
        let result = CalculatorEngine.calculate(
            target: 30, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.isEmpty)
        #expect(result.isExact)
    }

    @Test func disabledPlatesIgnored() {
        var inv = lbsInventory
        inv[0] = PlateInventoryItem(weight: 45, isEnabled: false)
        let result = CalculatorEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.allSatisfy { $0.weight != 45 })
    }

    @Test func collarWeightSubtracted() {
        // 5 lb collar total (2.5 lb per side spring clips) — less weight available for plates
        let result = CalculatorEngine.calculate(
            target: 135, barWeight: 45, collarWeight: 5,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        // net = 135 - 45 - 5 = 85, per side = 42.5 — can load 35+5+2.5 = 42.5
        let totalLoaded = result.platesPerSide.map(\.weight).reduce(0, +)
        #expect(abs(totalLoaded - 42.5) < 0.01)
    }
}
