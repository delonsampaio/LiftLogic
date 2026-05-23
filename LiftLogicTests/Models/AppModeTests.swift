import Testing
@testable import LiftLogic

@Suite("AppMode")
struct AppModeTests {
    @Test func calcIsFree() {
        #expect(!AppMode.calc.requiresPro)
    }
    @Test func proModesRequirePro() {
        #expect(AppMode.warmup.requiresPro)
        #expect(AppMode.oneRM.requiresPro)
        #expect(AppMode.reverse.requiresPro)
    }
    @Test func displayNames() {
        #expect(AppMode.calc.displayName == "CALC")
        #expect(AppMode.warmup.displayName == "WARMUP")
        #expect(AppMode.oneRM.displayName == "1RM")
        #expect(AppMode.reverse.displayName == "↔ REV")
    }
}
