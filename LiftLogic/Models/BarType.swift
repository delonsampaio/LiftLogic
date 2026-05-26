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

    /// Compact label for the quick-toggle strip — omits weight so it fits on small screens.
    var stripLabel: String {
        switch self {
        case .olympic45lb:   return "Olympic"
        case .olympic35lb:   return "Women's"
        case .olympic20kg:   return "Olympic"
        case .olympic15kg:   return "Women's"
        case .trapHex:       return "Trap/Hex"
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
        switch self {
        case .olympic45lb:
            let lbs = 45.0
            return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
        case .olympic35lb:
            let lbs = 35.0
            return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
        case .olympic20kg:
            let kg = 20.0
            return unit == .kg ? kg : WeightUnit.kg.convert(kg, to: .lbs)
        case .olympic15kg:
            let kg = 15.0
            return unit == .kg ? kg : WeightUnit.kg.convert(kg, to: .lbs)
        case .trapHex:
            let lbs = 55.0
            return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
        case .safetySquat:
            let lbs = 65.0
            return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
        case .ezCurl:
            let lbs = 25.0
            return unit == .lbs ? lbs : WeightUnit.lbs.convert(lbs, to: .kg)
        case .custom:
            return 0
        }
    }
}
