import Foundation
import Testing
@testable import LiftLogic

@Suite("WidgetDeepLink")
struct WidgetDeepLinkTests {
    @Test func parsesWellFormedURL() {
        let url = URL(string: "liftlogic://calc?weight=225.0&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == 225.0)
    }

    @Test func rejectsWrongScheme() {
        let url = URL(string: "https://calc?weight=225.0&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsWrongHost() {
        let url = URL(string: "liftlogic://warmup?weight=225.0&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsMissingWeightParam() {
        let url = URL(string: "liftlogic://calc?unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsNonNumericWeight() {
        let url = URL(string: "liftlogic://calc?weight=abc&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsNonFiniteWeight() {
        let url = URL(string: "liftlogic://calc?weight=nan&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsNonPositiveWeight() {
        let url = URL(string: "liftlogic://calc?weight=-500&unit=lbs")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }
}
