import Testing
@testable import LiftLogic

@Suite("WarmupEngine")
struct WarmupEngineTests {
    let inventory: [PlateInventoryItem] = [45, 25, 10, 5, 2.5].map {
        PlateInventoryItem(weight: $0, isEnabled: true)
    }

    @Test func fiveRows() {
        let sets = WarmupEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: inventory, unit: .lbs, isSingleSided: false
        )
        #expect(sets.count == 5)
    }
    @Test func percentagesCorrect() {
        let sets = WarmupEngine.calculate(
            target: 225, barWeight: 45, collarWeight: 0,
            inventory: inventory, unit: .lbs, isSingleSided: false
        )
        #expect(sets.map(\.percentage) == [50, 60, 70, 80, 90])
    }
    @Test func fiftyPercentTarget() {
        let sets = WarmupEngine.calculate(
            target: 200, barWeight: 45, collarWeight: 0,
            inventory: inventory, unit: .lbs, isSingleSided: false
        )
        #expect(sets[0].targetWeight == 100)
    }
    @Test func lowPercentageBelowBarLoadsNoPlates() {
        // 50% of 80 lb = 40 lb, below the 45 lb bar → no plates, target still reported.
        let sets = WarmupEngine.calculate(
            target: 80, barWeight: 45, collarWeight: 0,
            inventory: inventory, unit: .lbs, isSingleSided: false
        )
        #expect(sets[0].targetWeight == 40)
        #expect(sets[0].platesPerSide.isEmpty)
    }
}
