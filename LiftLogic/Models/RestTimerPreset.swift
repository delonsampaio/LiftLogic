import Foundation

struct RestTimerPreset: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var seconds: Int

    init(id: UUID = UUID(), name: String, seconds: Int) {
        self.id = id
        self.name = name
        self.seconds = seconds
    }
}
