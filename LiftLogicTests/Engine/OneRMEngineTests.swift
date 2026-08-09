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
    @Test func percentOf1RMKnownCellsMatchTable() {
        #expect(OneRMEngine.percentOf1RM(reps: 1, rpe: 10.0) == 100.0)
        #expect(OneRMEngine.percentOf1RM(reps: 5, rpe: 8.0) == 81.1)
        #expect(OneRMEngine.percentOf1RM(reps: 12, rpe: 6.0) == 61.8)
        #expect(OneRMEngine.percentOf1RM(reps: 1, rpe: 6.0) == 86.3)
    }
    @Test func percentOf1RMOutOfRangeRepsReturnsNil() {
        #expect(OneRMEngine.percentOf1RM(reps: 13, rpe: 10.0) == nil)
        #expect(OneRMEngine.percentOf1RM(reps: 0, rpe: 10.0) == nil)
    }
    @Test func percentOf1RMOutOfRangeRPEReturnsNil() {
        #expect(OneRMEngine.percentOf1RM(reps: 5, rpe: 5.5) == nil)
        #expect(OneRMEngine.percentOf1RM(reps: 5, rpe: 10.5) == nil)
    }
    @Test func percentOf1RMOffGridDecimalReturnsNil() {
        // 8.1 isn't a stepper-reachable value (steps are 0.5), but the table lookup
        // must not silently match a neighboring cell for it — see Global Constraints
        // on why the table is Int-keyed.
        #expect(OneRMEngine.percentOf1RM(reps: 5, rpe: 8.1) == nil)
    }
}
