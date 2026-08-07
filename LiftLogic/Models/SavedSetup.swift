import Foundation

struct SavedSetup: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let weight: Double
    let barType: BarType
    let collarType: CollarType
    let unit: WeightUnit
    let isSingleSided: Bool
    let createdAt: Date
}
