import Foundation

/// Relative-strength scoring formulas (Wilks, DOTS, IPF GL Points). All three take a
/// bodyweight and a lifted weight in kilograms and return a unitless "points" score —
/// the official published coefficients below are calibrated in kg, so inputs must
/// already be converted before calling.
struct RelativeStrengthEngine {
    static func calculate(bodyweightKg: Double, sex: Sex, liftedKg: Double) -> RelativeStrengthResult {
        RelativeStrengthResult(
            wilks: wilksScore(bodyweightKg: bodyweightKg, sex: sex, liftedKg: liftedKg),
            dots: dotsScore(bodyweightKg: bodyweightKg, sex: sex, liftedKg: liftedKg),
            ipfGL: ipfGLScore(bodyweightKg: bodyweightKg, sex: sex, liftedKg: liftedKg)
        )
    }

    private static func wilksScore(bodyweightKg x: Double, sex: Sex, liftedKg: Double) -> Double {
        let c: (a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)
        switch sex {
        case .male:
            c = (-216.0475144, 16.2606339, -0.002388645, -0.00113732, 7.01863e-6, -1.291e-8)
        case .female:
            c = (594.31747775582, -27.23842536447, 0.82112226871, -0.00930733913, 4.731582e-5, -9.054e-8)
        }
        let denom = c.a + c.b * x + c.c * x * x + c.d * pow(x, 3) + c.e * pow(x, 4) + c.f * pow(x, 5)
        return (500 / denom) * liftedKg
    }

    private static func dotsScore(bodyweightKg x: Double, sex: Sex, liftedKg: Double) -> Double {
        let c: (a: Double, b: Double, c: Double, d: Double, e: Double)
        switch sex {
        case .male:
            c = (-307.75076, 24.0900756, -0.1918759221, 0.0007391293, -0.000001093)
        case .female:
            c = (-57.96288, 13.6175032, -0.1126655495, 0.0005158568, -0.0000010706)
        }
        let denom = c.a + c.b * x + c.c * x * x + c.d * pow(x, 3) + c.e * pow(x, 4)
        return (500 / denom) * liftedKg
    }

    private static func ipfGLScore(bodyweightKg x: Double, sex: Sex, liftedKg: Double) -> Double {
        let c: (a: Double, b: Double, c: Double)
        switch sex {
        case .male:
            c = (1199.72839, 1025.18162, 0.00921)
        case .female:
            c = (610.32796, 1045.59282, 0.03048)
        }
        let denom = c.a - c.b * exp(-c.c * x)
        return (100 / denom) * liftedKg
    }
}
