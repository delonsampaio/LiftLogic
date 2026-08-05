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

    // MARK: — 11-plate cap

    @Test func elevenPlateCapEnforced() {
        // With only 2.5 lb plates and a 2000 lb target, hundreds of plates would be
        // needed — but the engine must stop at 11 per side.
        let inv = [PlateInventoryItem(weight: 2.5, isEnabled: true)]
        let result = CalculatorEngine.calculate(
            target: 2000, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.count == 11)
    }

    @Test func elevenPlateCapExactBoundary() {
        // Exactly 11 plates worth of weight should load all 11; 12 would need the cap.
        // 45 bar + 11×45 per side × 2 = 45 + 990 = 1035 lb
        let result = CalculatorEngine.calculate(
            target: 1035, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.count == 11)
        #expect(result.isExact)
    }

    // MARK: — Specific weight breakdowns (mirrors delta-toast test cases)

    @Test func exactBreakdown135Lbs() {
        let result = CalculatorEngine.calculate(
            target: 135, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        #expect(result.platesPerSide.count == 1)
        #expect(result.platesPerSide[0].weight == 45)
    }

    @Test func exactBreakdown225Lbs() {
        let result = CalculatorEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 2)
    }

    @Test func exactBreakdown350Lbs() {
        // 350 = 45 bar + 2×(3×45 + 10 + 5 + 2.5)
        let result = CalculatorEngine.calculate(
            target: 350, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 3)
        #expect(weights.filter { $0 == 10 }.count == 1)
        #expect(weights.filter { $0 == 5 }.count == 1)
        #expect(weights.filter { $0 == 2.5 }.count == 1)
    }

    @Test func exactBreakdown440Lbs() {
        // 440 = 45 bar + 2×(4×45 + 10 + 5 + 2.5)
        let result = CalculatorEngine.calculate(
            target: 440, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 4)
        #expect(weights.filter { $0 == 10 }.count == 1)
        #expect(weights.filter { $0 == 5 }.count == 1)
        #expect(weights.filter { $0 == 2.5 }.count == 1)
    }

    @Test func exactBreakdown500Lbs() {
        // 500 = 45 bar + 2×(5×45 + 2.5)
        let result = CalculatorEngine.calculate(
            target: 500, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 5)
        #expect(weights.filter { $0 == 2.5 }.count == 1)
        #expect(result.platesPerSide.count == 6)
    }

    @Test func exactBreakdown590Lbs() {
        // 590 = 45 bar + 2×(6×45 + 2.5)
        let result = CalculatorEngine.calculate(
            target: 590, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 6)
        #expect(weights.filter { $0 == 2.5 }.count == 1)
        #expect(result.platesPerSide.count == 7)
    }

    @Test func exactBreakdown315Lbs() {
        // 315 = 45 bar + 2×(3×45) — powerlifting milestone
        let result = CalculatorEngine.calculate(
            target: 315, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 45 }.count == 3)
        #expect(result.platesPerSide.count == 3)
    }

    // MARK: — Plate quantity limits (feature #63)

    @Test func quantityLimitCapsPlatesPerSide() {
        // Gym owns only 2× 45 lb plates → 1 per side. A 315 target wants 3 per side.
        let inv = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 2)]
        let result = CalculatorEngine.calculate(
            target: 315, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.count == 1)
        #expect(!result.isExact)
    }

    @Test func oddQuantityRoundsDownPerSide() {
        // 3 plates owned can't load symmetrically past 1 per side (3/2 = 1).
        let inv = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 3)]
        let result = CalculatorEngine.calculate(
            target: 315, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(result.platesPerSide.count == 1)
    }

    @Test func singleSidedUsesFullQuantity() {
        // Single-sided loads one side, so all owned plates are usable there.
        let inv = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 3)]
        let result = CalculatorEngine.calculate(
            target: 500, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: true
        )
        #expect(result.platesPerSide.count == 3)
    }

    // MARK: — Shortage reason inference

    @Test func shortageReasonNoneWhenExact() {
        let result = CalculatorEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(result.shortageReason == .none)
    }

    @Test func shortageReasonUnsupportedWhenInventoryUnlimited() {
        // Every plate is unlimited but 228 simply isn't loadable with these sizes.
        let result = CalculatorEngine.calculate(
            target: 228, barWeight: 45, collarWeight: 0,
            inventory: lbsInventory, unit: .lbs, isSingleSided: false
        )
        #expect(!result.isExact)
        #expect(result.shortageReason == .unsupportedIncrement)
    }

    @Test func shortageReasonOutOfPlatesWhenQuantityLimited() {
        // A finite quantity is the reason the exact target can't be reached.
        let inv = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 2)]
        let result = CalculatorEngine.calculate(
            target: 315, barWeight: 45, collarWeight: 0,
            inventory: inv, unit: .lbs, isSingleSided: false
        )
        #expect(!result.isExact)
        #expect(result.shortageReason == .outOfPlates)
    }

    @Test func kgBreakdown100kg() {
        // 100 kg = 20 kg bar + 2×(1×25 + 1×15) per side
        let inv: [PlateInventoryItem] = [25, 20, 15, 10, 5, 2.5, 1.25].map {
            PlateInventoryItem(weight: $0, isEnabled: true)
        }
        let result = CalculatorEngine.calculate(
            target: 100, barWeight: 20, collarWeight: 0,
            inventory: inv, unit: .kg, isSingleSided: false
        )
        #expect(result.isExact)
        let weights = result.platesPerSide.map(\.weight)
        #expect(weights.filter { $0 == 25 }.count == 1)
        #expect(weights.filter { $0 == 15 }.count == 1)
    }
}
