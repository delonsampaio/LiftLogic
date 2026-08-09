import Testing
@testable import LiftLogic

@Suite("QRCodeService")
struct QRCodeServiceTests {
    @Test func generateImageReturnsNonNilForValidString() {
        let image = QRCodeService.generateImage(from: "test payload")
        #expect(image != nil)
    }

    @Test func generateImageReturnsNonNilForTypicalPayloadLength() {
        let encoded = PartnerCodeService.encode(
            weight: 225, barType: .olympic45lb, collarType: .none,
            unit: .lbs, isSingleSided: false
        )
        #expect(encoded != nil)
        let image = QRCodeService.generateImage(from: encoded!)
        #expect(image != nil)
    }
}
