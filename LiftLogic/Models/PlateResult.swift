import Foundation

struct PlateResult {
    let platesPerSide: [LoadedPlate]
    let totalWeight: Double
    let remainder: Double  // always >= 0 (CalculatorEngine enforces max(0, remaining))

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
