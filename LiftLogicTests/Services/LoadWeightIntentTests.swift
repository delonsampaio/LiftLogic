import Foundation
import Testing
@testable import LiftLogic

@Suite("LoadWeightIntent")
struct LoadWeightIntentTests {
    @Test func calcURLRoundTripsThroughWidgetDeepLink() {
        let url = LoadWeightIntent.calcURL(for: 225.0)
        #expect(url != nil)
        #expect(WidgetDeepLink.parseCalcWeight(from: url!)?.weight == 225.0)
    }

    @Test func calcURLRoundTripsFractionalWeight() {
        let url = LoadWeightIntent.calcURL(for: 47.5)
        #expect(url != nil)
        #expect(WidgetDeepLink.parseCalcWeight(from: url!)?.weight == 47.5)
    }

    @Test func calcURLUsesLiftLogicSchemeAndCalcHost() {
        let url = LoadWeightIntent.calcURL(for: 100.0)
        #expect(url?.scheme == "liftlogic")
        #expect(url?.host == "calc")
    }
}
