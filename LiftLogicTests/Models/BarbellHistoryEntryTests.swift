import Testing
import Foundation
@testable import LiftLogic

@Suite("BarbellHistoryEntry")
struct BarbellHistoryEntryTests {
    @Test func entryWithCustomBarWeightRoundTripsThroughCodable() throws {
        let entry = BarbellHistoryEntry(id: UUID(), weight: 225, barType: .custom, collarType: .none,
                                         unit: .lbs, isSingleSided: false, customBarWeight: 33,
                                         recordedAt: Date(timeIntervalSince1970: 0))
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BarbellHistoryEntry.self, from: data)
        #expect(decoded == entry)
        #expect(decoded.customBarWeight == 33)
    }

    @Test func entryWithNilCustomBarWeightRoundTripsThroughCodable() throws {
        let entry = BarbellHistoryEntry(id: UUID(), weight: 225, barType: .olympic45lb, collarType: .none,
                                         unit: .lbs, isSingleSided: false, customBarWeight: nil,
                                         recordedAt: Date(timeIntervalSince1970: 0))
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(BarbellHistoryEntry.self, from: data)
        #expect(decoded == entry)
        #expect(decoded.customBarWeight == nil)
    }

    @Test func entryDecodesLegacyJSONMissingCustomBarWeightAsNil() throws {
        let legacyJSON = """
        {"id":"00000000-0000-0000-0000-000000000001","weight":225,
        "barType":"olympic45lb","collarType":"none","unit":"lbs","isSingleSided":false,
        "recordedAt":0}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(BarbellHistoryEntry.self, from: legacyJSON)
        #expect(decoded.customBarWeight == nil)
        #expect(decoded.weight == 225)
    }
}
