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

    @Test func savedSetupWithCustomBarWeightRoundTripsThroughCodable() throws {
        let setup = SavedSetup(id: UUID(), name: "Custom Bar Squat", weight: 225, barType: .custom,
                                collarType: .none, unit: .lbs, isSingleSided: false,
                                customBarWeight: 33, createdAt: Date(timeIntervalSince1970: 0))
        let data = try JSONEncoder().encode(setup)
        let decoded = try JSONDecoder().decode(SavedSetup.self, from: data)
        #expect(decoded == setup)
        #expect(decoded.customBarWeight == 33)
    }

    @Test func savedSetupDecodesLegacyJSONMissingCustomBarWeightAsNil() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","name":"Squat","weight":225,
        "barType":"olympic45lb","collarType":"none","unit":"lbs","isSingleSided":false,
        "createdAt":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SavedSetup.self, from: legacyJSON)
        #expect(decoded.customBarWeight == nil)
        #expect(decoded.name == "Squat")
    }
}
