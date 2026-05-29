import Testing
@testable import LiftLogic

@Suite("OneRMEngine")
struct OneRMEngineTests {
    @Test func epleyFormula() {
        let result = OneRMEngine.calculate(weight: 225, reps: 5)
        let expected = 225 * (1 + 5.0/30)
        #expect(abs(result.epley - expected) < 0.01)
    }
    @Test func brzyckiFormula() {
        let result = OneRMEngine.calculate(weight: 225, reps: 5)
        let expected = 225.0 * 36 / (37 - 5)
        #expect(abs(result.brzycki - expected) < 0.01)
    }
    @Test func averageIsHalfSum() {
        let result = OneRMEngine.calculate(weight: 100, reps: 10)
        let expectedEpley   = 100.0 * (1 + 10.0 / 30)
        let expectedBrzycki = 100.0 * 36 / (37.0 - 10)
        let expectedAverage = (expectedEpley + expectedBrzycki) / 2
        #expect(abs(result.average - expectedAverage) < 0.001)
    }
    @Test func repsClampedAtMax() {
        let result = OneRMEngine.calculate(weight: 100, reps: 40)
        #expect(result.reps == 15)
    }
    @Test func repsClampedAtMin() {
        let result = OneRMEngine.calculate(weight: 100, reps: 0)
        #expect(result.reps == 1)
    }
}
