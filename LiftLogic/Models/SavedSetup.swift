import Foundation

struct SavedSetup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let weight: Double
    let barType: BarType
    let collarType: CollarType
    let unit: WeightUnit
    let isSingleSided: Bool
    let customBarWeight: Double?
    let createdAt: Date

    init(id: UUID, name: String, weight: Double, barType: BarType, collarType: CollarType, unit: WeightUnit, isSingleSided: Bool, customBarWeight: Double? = nil, createdAt: Date) {
        self.id = id
        self.name = name
        self.weight = weight
        self.barType = barType
        self.collarType = collarType
        self.unit = unit
        self.isSingleSided = isSingleSided
        self.customBarWeight = customBarWeight
        self.createdAt = createdAt
    }
}
