enum BarType: String, Codable, CaseIterable, Identifiable {
    case olympic45lb
    case olympic35lb
    case olympic20kg
    case olympic15kg
    case trapHex
    case safetySquat
    case ezCurl
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .olympic45lb:   return "Olympic (45 lb)"
        case .olympic35lb:   return "Women's (35 lb)"
        case .olympic20kg:   return "Olympic (20 kg)"
        case .olympic15kg:   return "Women's (15 kg)"
        case .trapHex:       return "Trap / Hex"
        case .safetySquat:   return "Safety Squat"
        case .ezCurl:        return "EZ Curl"
        case .custom:        return "Custom"
        }
    }

    var isSpecialty: Bool {
        switch self {
        case .olympic45lb, .olympic35lb, .olympic20kg, .olympic15kg: return false
        case .trapHex, .safetySquat, .ezCurl, .custom: return true
        }
    }

    func weight(in unit: WeightUnit) -> Double {
        let lbs: Double
        switch self {
        case .olympic45lb:  lbs = 45
        case .olympic35lb:  lbs = 35
        case .olympic20kg:  lbs = 44.09
        case .olympic15kg:  lbs = 33.07
        case .trapHex:      lbs = 55
        case .safetySquat:  lbs = 65
        case .ezCurl:       lbs = 25
        case .custom:       lbs = 0  // CalculatorViewModel resolves the actual weight
        }
        return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
    }
}
