import Testing
@testable import LiftLogic

@Suite("RelativeStrengthEngine")
struct RelativeStrengthEngineTests {

    // MARK: — Wilks (exact values from the published Robert Wilks coefficient table)

    @Test func wilksCoefficientMale69point3kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 69.3, sex: .male, liftedKg: 100)
        #expect(abs(result.wilks / 100 - 0.7552) < 0.001)
    }

    @Test func wilksCoefficientMale100kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 100.0, sex: .male, liftedKg: 100)
        #expect(abs(result.wilks / 100 - 0.6086) < 0.001)
    }

    @Test func wilksCoefficientFemale60kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 60.0, sex: .female, liftedKg: 100)
        #expect(abs(result.wilks / 100 - 1.1149) < 0.001)
    }

    @Test func wilksCoefficientFemale100kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 100.0, sex: .female, liftedKg: 100)
        #expect(abs(result.wilks / 100 - 0.8326) < 0.001)
    }

    // MARK: — DOTS (values computed from the documented formula/coefficients)

    @Test func dotsCoefficientMale80kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 80.0, sex: .male, liftedKg: 100)
        #expect(abs(result.dots / 100 - 0.6896) < 0.005)
    }

    @Test func dotsCoefficientFemale60kg() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 60.0, sex: .female, liftedKg: 100)
        #expect(abs(result.dots / 100 - 1.1086) < 0.005)
    }

    // MARK: — IPF GL Points (values computed from the documented formula/coefficients)

    @Test func ipfGLMale80kgBodyweight300kgLift() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 80.0, sex: .male, liftedKg: 300)
        #expect(abs(result.ipfGL - 42.3) < 0.5)
    }

    @Test func ipfGLFemale60kgBodyweight400kgLift() {
        let result = RelativeStrengthEngine.calculate(bodyweightKg: 60.0, sex: .female, liftedKg: 400)
        #expect(abs(result.ipfGL - 90.4) < 0.5)
    }

    // MARK: — Sanity: scores scale linearly with lifted weight

    @Test func scoresScaleLinearlyWithLiftedWeight() {
        let half = RelativeStrengthEngine.calculate(bodyweightKg: 80.0, sex: .male, liftedKg: 100)
        let double = RelativeStrengthEngine.calculate(bodyweightKg: 80.0, sex: .male, liftedKg: 200)
        #expect(abs(double.wilks - half.wilks * 2) < 0.001)
        #expect(abs(double.dots - half.dots * 2) < 0.001)
        #expect(abs(double.ipfGL - half.ipfGL * 2) < 0.001)
    }
}
