enum CollarType: String, Codable, CaseIterable {
    case none, springClip, competition

    var displayName: String {
        switch self {
        case .none:        return "No Collar"
        case .springClip:  return "Spring Clip"
        case .competition: return "Competition"
        }
    }

    // lbs and kg values are independent rounded constants, not conversions — intentional for friendly display
    func weightPerCollar(in unit: WeightUnit) -> Double {
        switch self {
        case .none:        return 0
        case .springClip:  return unit == .lbs ? 0.5 : 0.23
        case .competition: return unit == .lbs ? 5.5 : 2.5
        }
    }

    func totalWeight(in unit: WeightUnit) -> Double {
        weightPerCollar(in: unit) * 2
    }
}
