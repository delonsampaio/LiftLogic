enum WeightUnit: String, Codable, CaseIterable {
    case lbs, kg

    var symbol: String { rawValue }

    func convert(_ value: Double, to other: WeightUnit) -> Double {
        guard self != other else { return value }
        switch (self, other) {
        case (.lbs, .kg): return (value * 0.453592 * 100).rounded() / 100
        case (.kg, .lbs): return (value * 2.20462 * 100).rounded() / 100
        default: return value
        }
    }
}
