import Testing
@testable import LiftLogic

@Suite("ProGate")
struct ProGateTests {
    @Test func allowsWhenNotProGated() {
        #expect(ProGate.isAllowed(requiresPro: false, isPro: false))
    }

    @Test func allowsWhenProGatedAndUserIsPro() {
        #expect(ProGate.isAllowed(requiresPro: true, isPro: true))
    }

    @Test func deniesWhenProGatedAndUserIsNotPro() {
        #expect(!ProGate.isAllowed(requiresPro: true, isPro: false))
    }
}
