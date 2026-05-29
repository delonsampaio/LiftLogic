import Testing
import Foundation
@testable import LiftLogic

@MainActor
@Suite("CalculatorViewModel")
struct CalculatorViewModelTests {

    private func freshSettings() -> AppSettings {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        return AppSettings()
    }

    // MARK: — defaultBar honored on init (bug fix)

    @Test func selectedBarMatchesDefaultBarFromSettings() {
        let settings = freshSettings()
        settings.defaultBar = .olympic20kg
        let vm = CalculatorViewModel(settings: settings)
        #expect(vm.selectedBar == .olympic20kg)
    }

    // MARK: — Numpad input

    @Test func appendDigitBuildsString() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("2")
        vm.appendDigit("5")
        #expect(vm.inputString == "125")
        #expect(vm.targetWeight == 125)
    }

    @Test func decimalPointOnlyAddedOnce() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("2")
        vm.appendDigit(".")
        vm.appendDigit("5")
        vm.appendDigit(".")
        #expect(vm.inputString == "2.5")
    }

    @Test func deleteRemovesLastDigit() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("2")
        vm.deleteLastDigit()
        #expect(vm.inputString == "1")
    }

    // MARK: — Recent weights pollution fix (bug fix)

    @Test func commitIgnoredBelowBarWeight() {
        let settings = freshSettings()
        settings.recentWeights = []
        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("1")
        vm.commitWeight()  // 1 lb < 45 lb bar
        #expect(settings.recentWeights.isEmpty)
    }

    @Test func commitAcceptedAtOrAboveBarWeight() {
        let settings = freshSettings()
        settings.recentWeights = []
        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("1")
        vm.appendDigit("2")
        vm.appendDigit("5")
        vm.commitWeight()
        #expect(settings.recentWeights == [125])
    }

    // MARK: — Increment / decrement

    @Test func incrementUsesSmallestEnabledPlate() {
        let settings = freshSettings()
        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")
        vm.increment()
        // smallest enabled lbs plate is 2.5 → step is 2.5 × 2 = 5
        #expect(vm.targetWeight == 105)
    }

    @Test func decrementClampsToZero() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("3")
        vm.decrement()
        #expect(vm.targetWeight == 0)
        #expect(vm.inputString == "")
    }

    // MARK: — Reverse mode

    @Test func addPlateAppendsAndUndoRemoves() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        vm.addPlate(PlateInventoryItem(weight: 25, isEnabled: true))
        #expect(vm.reversePlateStack.count == 2)
        vm.undoLastPlate()
        #expect(vm.reversePlateStack.count == 1)
        #expect(vm.reversePlateStack.first?.weight == 45)
    }

    @Test func clearReverseStackEmptiesAll() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        vm.addPlate(PlateInventoryItem(weight: 35, isEnabled: true))
        vm.clearReverseStack()
        #expect(vm.reversePlateStack.isEmpty)
    }

    @Test func undoOnEmptyStackIsNoop() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.undoLastPlate()
        #expect(vm.reversePlateStack.isEmpty)
    }

    // MARK: — Weight cap

    @Test func appendDigitClampsAt2000Lbs() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("2")
        vm.appendDigit("2")
        vm.appendDigit("5")
        vm.appendDigit("0")  // "2250" → clamped to 2000
        #expect(vm.targetWeight == 2000)
    }

    @Test func suppressedCommitSkipsRevisionIncrement() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("2")
        vm.appendDigit("2")
        vm.appendDigit("5")
        vm.commitWeight()
        let revision = vm.commitRevision
        vm.appendDigit("0")  // "2250" → "2000", suppressNextCommit = true
        vm.commitWeight()    // should be suppressed
        #expect(vm.commitRevision == revision)
    }

    @Test func suppressedCommitKeepsBaselineAtPreviousWeight() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        let baselinePlateCount = vm.committedResult?.platesPerSide.count
        vm.appendDigit("0")  // "2250" → "2000", suppressNextCommit = true
        vm.commitWeight()    // suppressed — baseline must not advance to 2000 lb plates
        #expect(vm.committedResult?.platesPerSide.count == baselinePlateCount)
    }

    // MARK: — Delta toast correctness

    @Test func firstCommitProducesNoDelta() {
        // No prior committedResult → plateDelta returns [] → no toast
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        #expect(vm.lastDelta.isEmpty)
        #expect(vm.commitRevision == 1)
    }

    @Test func deltaFrom45To135AddsOne45PerSide() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "45"
        vm.commitWeight()        // bare bar → 0 plates
        vm.inputString = "135"
        vm.commitWeight()        // 1×45 per side → delta = [(45, +1)]
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == 1)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaFrom135To225AddsOne45PerSide() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "135"
        vm.commitWeight()
        vm.inputString = "225"
        vm.commitWeight()
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == 1)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaFrom500To590AddsOne45PerSide() {
        // 500 = bar + 2×(5×45+2.5)   590 = bar + 2×(6×45+2.5)
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "500"
        vm.commitWeight()
        vm.inputString = "590"
        vm.commitWeight()
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == 1)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaFrom350To440AddsOne45PerSide() {
        // 350 = bar + 2×(3×45+10+5+2.5)   440 = bar + 2×(4×45+10+5+2.5)
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "350"
        vm.commitWeight()
        vm.inputString = "440"
        vm.commitWeight()
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == 1)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaFrom135To45RemovesOne45PerSide() {
        // Stripping back to bare bar — should ask to REMOVE the plate
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "135"
        vm.commitWeight()
        vm.inputString = "45"
        vm.commitWeight()
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == -1)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaFrom315To45RemovesThree45PerSide() {
        // 315 = bar + 2×(3×45); stripping to bare bar removes all three per side
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "315"
        vm.commitWeight()
        vm.inputString = "45"
        vm.commitWeight()
        let change = vm.lastDelta.first(where: { $0.weight == 45 })?.change
        #expect(change == -3)
        #expect(vm.lastDelta.count == 1)
    }

    @Test func deltaToSameWeightIsEmpty() {
        // Committing the same weight twice should produce no delta
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        vm.inputString = "225"
        vm.commitWeight()
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func resetWeightClearsLastDelta() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        vm.inputString = "135"
        vm.commitWeight()
        // lastDelta should be non-empty at this point
        vm.resetWeight()
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func firstCommitAfterResetProducesNoDelta() {
        // Reset clears committedResult; next commit is treated as a first-time load
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        vm.inputString = "315"
        vm.commitWeight()
        vm.resetWeight()
        vm.inputString = "135"
        vm.commitWeight()
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func loadWeightProducesEmptyDelta() {
        // loadWeight advances the baseline before committing — no visible change
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        vm.commitWeight()
        vm.loadWeight(135)
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func incrementProducesEmptyDelta() {
        // +/- buttons mean "I'm loading this" — baseline advances, no toast
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")
        vm.commitWeight()
        vm.increment()
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func decrementProducesEmptyDelta() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("3")
        vm.appendDigit("5")
        vm.commitWeight()
        vm.decrement()
        #expect(vm.lastDelta.isEmpty)
    }

    @Test func commitRevisionIncreasesOnEachSettle() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "135"
        vm.commitWeight()
        vm.inputString = "225"
        vm.commitWeight()
        vm.inputString = "315"
        vm.commitWeight()
        #expect(vm.commitRevision == 3)
    }

}
