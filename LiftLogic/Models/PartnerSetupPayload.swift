import Foundation

struct PartnerSetupPayload: Codable, Equatable {
    let app: String
    let version: Int
    let weight: Double
    let barType: BarType
    let collarType: CollarType
    let unit: WeightUnit
    let isSingleSided: Bool
}
