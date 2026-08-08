enum Sex: String, Codable, CaseIterable {
    case male, female

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}
