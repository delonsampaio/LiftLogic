enum AppMode: String, Codable, CaseIterable {
    case calc, warmup, oneRM, reverse

    var displayName: String {
        switch self {
        case .calc:    return "CALC"
        case .warmup:  return "WARMUP"
        case .oneRM:   return "1RM"
        case .reverse: return "REV"
        }
    }

    var iconName: String {
        switch self {
        case .calc:    return "equal"
        case .warmup:  return "flame"
        case .oneRM:   return "chart.line.uptrend.xyaxis"
        case .reverse: return "arrow.left.arrow.right"
        }
    }

    var requiresPro: Bool { self != .calc }
}
