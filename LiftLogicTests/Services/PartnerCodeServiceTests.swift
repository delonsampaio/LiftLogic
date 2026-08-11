import Testing
@testable import LiftLogic

@Suite("PartnerCodeService")
struct PartnerCodeServiceTests {
    @Test func encodeThenDecodeRoundTrips() {
        let encoded = PartnerCodeService.encode(
            weight: 225, barType: .olympic45lb, collarType: .none,
            unit: .lbs, isSingleSided: false, customBarWeight: nil
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
            unit: .kg, isSingleSided: true, customBarWeight: nil
        )
        let decoded = PartnerCodeService.decode(encoded!)
        #expect(decoded?.weight == 100)
        #expect(decoded?.barType == .olympic20kg)
        #expect(decoded?.collarType == .competition)
        #expect(decoded?.unit == .kg)
        #expect(decoded?.isSingleSided == true)
    }

    @Test func encodeThenDecodeRoundTripsCustomBarWeight() {
        let encoded = PartnerCodeService.encode(
            weight: 135, barType: .custom, collarType: .none,
            unit: .lbs, isSingleSided: false, customBarWeight: 35
        )
        #expect(encoded != nil)
        let decoded = PartnerCodeService.decode(encoded!)
        #expect(decoded?.barType == .custom)
        #expect(decoded?.customBarWeight == 35)
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

    @Test func decodeRejectsAbsurdWeight() {
        let crafted = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":1e30,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(crafted) == nil)
    }

    @Test func decodeAcceptsWeightAtCapBoundary() {
        let atCapLbs = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":2000,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(atCapLbs)?.weight == 2000)

        let atCapKg = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":907,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"kg\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(atCapKg)?.weight == 907)
    }

    @Test func decodeRejectsAbsurdCustomBarWeight() {
        let crafted = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":135,\"barType\":\"custom\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false,\"customBarWeight\":1e30}"
        #expect(PartnerCodeService.decode(crafted) == nil)
    }

    @Test func decodeRejectsNegativeCustomBarWeight() {
        let crafted = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":135,\"barType\":\"custom\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false,\"customBarWeight\":-5}"
        #expect(PartnerCodeService.decode(crafted) == nil)
    }

    @Test func decodeAcceptsValidCustomBarWeight() {
        let valid = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":135,\"barType\":\"custom\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false,\"customBarWeight\":35}"
        #expect(PartnerCodeService.decode(valid)?.customBarWeight == 35)
    }

    @Test func decodeAcceptsNilCustomBarWeightOnNonCustomBar() {
        let noCustomBar = "{\"app\":\"liftlogic\",\"version\":1,\"weight\":225,\"barType\":\"olympic45lb\",\"collarType\":\"none\",\"unit\":\"lbs\",\"isSingleSided\":false}"
        #expect(PartnerCodeService.decode(noCustomBar) != nil)
        #expect(PartnerCodeService.decode(noCustomBar)?.customBarWeight == nil)
    }
}
