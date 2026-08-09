import Testing
@testable import LiftLogic

@Suite("PartnerCodeService")
struct PartnerCodeServiceTests {
    @Test func encodeThenDecodeRoundTrips() {
        let encoded = PartnerCodeService.encode(
            weight: 225, barType: .olympic45lb, collarType: .none,
            unit: .lbs, isSingleSided: false
        )
        #expect(encoded != nil)
        let decoded = PartnerCodeService.decode(encoded!)
        #expect(decoded?.weight == 225)
        #expect(decoded?.barType == .olympic45lb)
        #expect(decoded?.collarType == CollarType.none)
        #expect(decoded?.unit == .lbs)
        #expect(decoded?.isSingleSided == false)
    }

    @Test func encodeThenDecodeRoundTripsSingleSidedKg() {
        let encoded = PartnerCodeService.encode(
            weight: 100, barType: .olympic20kg, collarType: .competition,
            unit: .kg, isSingleSided: true
        )
        let decoded = PartnerCodeService.decode(encoded!)
        #expect(decoded?.weight == 100)
        #expect(decoded?.barType == .olympic20kg)
        #expect(decoded?.collarType == .competition)
        #expect(decoded?.unit == .kg)
        #expect(decoded?.isSingleSided == true)
    }

    @Test func decodeRejectsNonJSONString() {
        #expect(PartnerCodeService.decode("not json at all") == nil)
    }

    @Test func decodeRejectsWrongAppIdentifier() {
        let foreign = "{\"app\":\"otherapp\",\"version\":1,\"weight\":225,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(foreign) == nil)
    }

    @Test func decodeRejectsUnsupportedVersion() {
        let futureVersion = "{\"app\":\"liftlogic\",\"version\":99,\"weight\":225,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(futureVersion) == nil)
    }
}
