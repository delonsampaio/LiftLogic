import Foundation
import Testing
@testable import LiftLogic

@Suite("WidgetDeepLink")
struct WidgetDeepLinkTests {
    @Test func parsesWellFormedURL() {
        let url = URL(string: "liftlogic://calc?weight=225.0&unit=lbs")!
        let result = WidgetDeepLink.parseCalcWeight(from: url)
        #expect(result?.weight == 225.0)
        #expect(result?.unit == .lbs)
    }

    @Test func parsesKgUnit() {
        let url = URL(string: "liftlogic://calc?weight=100.0&unit=kg")!
        let result = WidgetDeepLink.parseCalcWeight(from: url)
        #expect(result?.weight == 100.0)
        #expect(result?.unit == .kg)
    }

    @Test func rejectsMissingUnitParam() {
        let url = URL(string: "liftlogic://calc?weight=225.0")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }

    @Test func rejectsInvalidUnitValue() {
        let url = URL(string: "liftlogic://calc?weight=225.0&unit=stone")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
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

    @Test func rejectsEmptyUnitParam() {
        let url = URL(string: "liftlogic://calc?weight=225.0&unit=")!
        #expect(WidgetDeepLink.parseCalcWeight(from: url) == nil)
    }
}
