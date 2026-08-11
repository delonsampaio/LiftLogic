import Testing
@testable import LiftLogic

@Suite("BarType")
struct BarTypeTests {
    @Test func olympic45Weight() {
        #expect(BarType.olympic45lb.weight(in: .lbs) == 45)
    }
    @Test func olympic20kgWeight() {
        #expect(BarType.olympic20kg.weight(in: .kg) == 20)
    }
}
