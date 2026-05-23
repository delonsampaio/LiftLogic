import Testing
@testable import LiftLogic

@Suite("CollarType")
struct CollarTypeTests {
    @Test func noneIsZero() {
        #expect(CollarType.none.totalWeight(in: .lbs) == 0)
    }
    @Test func springClipTotal() {
        #expect(CollarType.springClip.totalWeight(in: .lbs) == 1.0)
    }
    @Test func competitionTotalKg() {
        #expect(CollarType.competition.totalWeight(in: .kg) == 5.0)
    }
    @Test func competitionTotalLbs() {
        #expect(CollarType.competition.totalWeight(in: .lbs) == 11.0)
    }
}
