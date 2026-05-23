enum WeightUnit: String, Codable, CaseIterable {
    case lbs, kg

    var symbol: String { rawValue }

    func convert(_ value: Double, to other: WeightUnit) -> Double {
        guard self != other else { return value }
        let inKg = self == .lbs ? value * 0.453592 : value
        let result = other == .lbs ? inKg * 2.20462 : inKg
        return (result * 100).rounded() / 100
    }
}
