import Foundation

struct BarbellHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let weight: Double
    let barType: BarType
    let collarType: CollarType
    let unit: WeightUnit
    let isSingleSided: Bool
    let recordedAt: Date
}
