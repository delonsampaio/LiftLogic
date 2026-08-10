import Testing
import Foundation
@testable import LiftLogic

@Suite("SavedSetup")
struct SavedSetupTests {
    @Test func identicalSetupsAreEqual() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 0)
        let a = SavedSetup(id: id, name: "Squat", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        let b = SavedSetup(id: id, name: "Squat", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        #expect(a == b)
    }

    @Test func differingNameMakesSetupsUnequal() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 0)
        let a = SavedSetup(id: id, name: "Squat", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        let b = SavedSetup(id: id, name: "Bench", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        #expect(a != b)
    }

    @Test func differingIdMakesSetupsUnequal() {
        let date = Date(timeIntervalSince1970: 0)
        let a = SavedSetup(id: UUID(), name: "Squat", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        let b = SavedSetup(id: UUID(), name: "Squat", weight: 225, barType: .olympic45lb,
                            collarType: .none, unit: .lbs, isSingleSided: false, createdAt: date)
        #expect(a != b)
    }

    @Test func savedSetupArrayRoundTripsThroughCodable() throws {
        let setups = [
            SavedSetup(id: UUID(), name: "Squat", weight: 225, barType: .olympic45lb,
                       collarType: .none, unit: .lbs, isSingleSided: false, createdAt: Date(timeIntervalSince1970: 0)),
            SavedSetup(id: UUID(), name: "Bench", weight: 185, barType: .olympic45lb,
                       collarType: .springClip, unit: .lbs, isSingleSided: true, createdAt: Date(timeIntervalSince1970: 1000))
        ]
        let data = try JSONEncoder().encode(setups)
        let decoded = try JSONDecoder().decode([SavedSetup].self, from: data)
        #expect(decoded == setups)
    }
}
