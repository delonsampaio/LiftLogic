import Foundation

struct BarbellHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let weight: Double
    let barType: BarType
    let collarType: CollarType
    let unit: WeightUnit
    let isSingleSided: Bool
    let customBarWeight: Double?
    let recordedAt: Date

    init(id: UUID, weight: Double, barType: BarType, collarType: CollarType, unit: WeightUnit, isSingleSided: Bool, customBarWeight: Double? = nil, recordedAt: Date) {
        self.id = id
        self.weight = weight
        self.barType = barType
        self.collarType = collarType
        self.unit = unit
        self.isSingleSided = isSingleSided
        self.customBarWeight = customBarWeight
        self.recordedAt = recordedAt
    }
}
