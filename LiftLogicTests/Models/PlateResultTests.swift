import Testing
@testable import LiftLogic

@Suite("PlateResult")
struct PlateResultTests {
    @Test func groupedCollapsesDuplicates() {
        let plates = [LoadedPlate(weight: 45), LoadedPlate(weight: 45), LoadedPlate(weight: 25)]
        let result = PlateResult(platesPerSide: plates, totalWeight: 225, remainder: 0)
        let grouped = result.grouped
        #expect(grouped.count == 2)
        #expect(grouped[0].weight == 45)
        #expect(grouped[0].count == 2)
        #expect(grouped[1].weight == 25)
        #expect(grouped[1].count == 1)
    }
    @Test func zeroRemainderIsExact() {
        let result = PlateResult(platesPerSide: [], totalWeight: 45, remainder: 0)
        #expect(result.isExact)
    }
    @Test func positiveRemainderNotExact() {
        let result = PlateResult(platesPerSide: [], totalWeight: 226, remainder: 1.0)
        #expect(!result.isExact)
    }
    @Test func loadedPlateUniqueIDs() {
        let a = LoadedPlate(weight: 45)
        let b = LoadedPlate(weight: 45)
        #expect(a.id != b.id)
    }
    @Test func isExactEpsilonBoundary() {
        // remainder just under epsilon — should be treated as exact
        let result = PlateResult(platesPerSide: [], totalWeight: 100, remainder: 0.0009)
        #expect(result.isExact)
        // remainder at epsilon — NOT exact
        let result2 = PlateResult(platesPerSide: [], totalWeight: 100, remainder: 0.001)
        #expect(!result2.isExact)
    }
}
