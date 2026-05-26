import Foundation

enum ShortageReason {
    /// Result is exact — no shortage.
    case none
    /// No enabled plate is small enough to fill the remainder. Adding more
    /// of the existing plates won't help.
    case unsupportedIncrement
    /// User's quantity limits prevented loading enough plates. With more
    /// of the existing plates, the exact target would be achievable.
    case outOfPlates
}

struct PlateResult {
    let platesPerSide: [LoadedPlate]
    let totalWeight: Double
    let remainder: Double  // always >= 0 (CalculatorEngine enforces max(0, remaining))
    var shortageReason: ShortageReason = .none

    var isExact: Bool { remainder >= 0 && remainder < 0.001 }

    var grouped: [(weight: Double, count: Int)] {
        var result: [(weight: Double, count: Int)] = []
        for plate in platesPerSide {
            if let idx = result.firstIndex(where: { $0.weight == plate.weight }) {
                result[idx].count += 1
            } else {
                result.append((weight: plate.weight, count: 1))
            }
        }
        return result
    }
}
