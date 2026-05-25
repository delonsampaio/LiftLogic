struct PlateInventoryItem: Identifiable, Hashable, Codable {
    var id: Double { weight }
    let weight: Double
    var isEnabled: Bool
    var quantity: Int   // total plates owned; Int.max = unlimited

    init(weight: Double, isEnabled: Bool, quantity: Int = Int.max) {
        self.weight = weight
        self.isEnabled = isEnabled
        self.quantity = quantity
    }

    // Backwards-compatible decoder: old JSON has no quantity → default to unlimited
    enum CodingKeys: String, CodingKey { case weight, isEnabled, quantity }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weight    = try c.decode(Double.self, forKey: .weight)
        isEnabled = try c.decode(Bool.self,   forKey: .isEnabled)
        quantity  = try c.decodeIfPresent(Int.self, forKey: .quantity) ?? Int.max
    }
}
