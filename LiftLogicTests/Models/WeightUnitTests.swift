import Testing
@testable import LiftLogic

@Suite("WeightUnit")
struct WeightUnitTests {
    @Test func lbsToKg() {
        #expect(WeightUnit.lbs.convert(45, to: .kg) == 20.41, "45 lbs ≈ 20.41 kg")
    }
    @Test func kgToLbs() {
        #expect(WeightUnit.kg.convert(20, to: .lbs) == 44.09, "20 kg ≈ 44.09 lbs")
    }
    @Test func sameUnit() {
        #expect(WeightUnit.lbs.convert(100, to: .lbs) == 100)
    }
    @Test func symbol() {
        #expect(WeightUnit.lbs.symbol == "lbs")
        #expect(WeightUnit.kg.symbol == "kg")
    }
    @Test func roundTripIsApproximate() {
        let original = 100.0
        let roundTripped = WeightUnit.kg.convert(
            WeightUnit.lbs.convert(original, to: .kg),
            to: .lbs
        )
        #expect(abs(roundTripped - original) < 0.1)
    }
}
