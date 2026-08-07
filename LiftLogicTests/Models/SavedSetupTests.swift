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
}
