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

    // MARK: — Reverse-mode inventory limits

    @Test func reverseTotalIncludesBarAndBothSides() {
        let vm = CalculatorViewModel(settings: freshSettings())   // 45 lb bar default
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        #expect(vm.reverseTotal == 135)                          // 45 bar + 2×45
    }

    @Test func reverseTotalSingleSidedCountsOneSide() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.isSingleSided = true
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        #expect(vm.reverseTotal == 90)                           // 45 bar + 1×45
    }

    @Test func canAddPlateRespectsQuantityLimit() {
        let settings = freshSettings()
        settings.lbsInventory = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 2)]
        let vm = CalculatorViewModel(settings: settings)
        let plate = settings.lbsInventory[0]
        vm.addPlate(plate)                        // 1 per side (quantity 2 / 2 sides)
        #expect(vm.reverseCount(for: 45) == 1)
        #expect(vm.canAddPlate(plate) == false)   // a 2nd per side would exceed the limit
    }

    @Test func reverseAllInventoryExhaustedWhenLimitReached() {
        let settings = freshSettings()
        settings.lbsInventory = [PlateInventoryItem(weight: 45, isEnabled: true, quantity: 2)]
        let vm = CalculatorViewModel(settings: settings)
        #expect(!vm.reverseAllInventoryExhausted)
        vm.addPlate(settings.lbsInventory[0])
        #expect(vm.reverseHitInventoryLimit)
        #expect(vm.reverseAllInventoryExhausted)
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

    // MARK: — Closest-loadable / shortfall (per-side remainder → total)

    @Test func totalShortDoublesPerSideRemainderForTwoSidedBar() {
        // 228 lb, 45 bar, standard plates: per-side loads 2×45 = 90, leaving 1.5/side.
        // The bar is 1.5 short on EACH side → 3.0 lb short in total.
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "228"
        #expect(abs(vm.totalShort - 3.0) < 0.001)
        #expect(abs(vm.closestLoadableWeight - 225.0) < 0.001)
    }

    @Test func totalShortEqualsPerSideRemainderForSingleSidedBar() {
        // Single-sided: all net weight on one side, so the shortfall is not doubled.
        // 101 lb, 45 bar, single side: 45+10 = 55 loaded, 1 lb short.
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.isSingleSided = true
        vm.inputString = "101"
        #expect(abs(vm.totalShort - 1.0) < 0.001)
        #expect(abs(vm.closestLoadableWeight - 100.0) < 0.001)
    }

    @Test func totalShortIsZeroWhenExact() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"
        #expect(vm.totalShort == 0)
        #expect(vm.closestLoadableWeight == 225)
    }

    // MARK: — Mode-aware plate grouping (used by the share card)

    @Test func displayGroupedReflectsReverseStackInReverseMode() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.currentMode = .reverse
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        vm.addPlate(PlateInventoryItem(weight: 45, isEnabled: true))
        vm.addPlate(PlateInventoryItem(weight: 25, isEnabled: true))
        let grouped = vm.displayGrouped
        #expect(grouped.first?.weight == 45)
        #expect(grouped.first?.count == 2)
        #expect(grouped.contains { $0.weight == 25 && $0.count == 1 })
    }

    @Test func displayGroupedReflectsCalcResultInCalcMode() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.inputString = "225"          // 2×45 per side
        let grouped = vm.displayGrouped
        #expect(grouped.first?.weight == 45)
        #expect(grouped.first?.count == 2)
    }

}
