enum AppMode: String, Codable, CaseIterable {
    case calc, warmup, oneRM, reverse

    var displayName: String {
        switch self {
        case .calc:    return "CALC"
        case .warmup:  return "WARMUP"
        case .oneRM:   return "1RM"
        case .reverse: return "↔ REV"
        }
    }

    var requiresPro: Bool { self != .calc }
}
