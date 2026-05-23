struct PlateInventoryItem: Identifiable, Hashable, Codable {
    var id: Double { weight }
    let weight: Double
    var isEnabled: Bool
}
