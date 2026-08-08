import Foundation

struct WarmupPercentageStep: Identifiable, Codable, Equatable {
    let id: UUID
    var percentage: Int
}
