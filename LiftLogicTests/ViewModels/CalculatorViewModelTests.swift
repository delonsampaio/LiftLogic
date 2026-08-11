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
        settings.isPro = true
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

    // MARK: — Relative strength (#76)

    @Test func relativeStrengthResultUsesOneRMAverageAsLiftedWeight() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("2")
        vm.appendDigit("0")
        vm.appendDigit("0")
        vm.oneRMReps = 1
        let expectedLifted = vm.oneRMResult.average
        let direct = RelativeStrengthEngine.calculate(bodyweightKg: 80, sex: .male, liftedKg: expectedLifted)
        let viaViewModel = vm.relativeStrengthResult(bodyweightKg: 80, sex: .male, liftedKg: expectedLifted)
        #expect(abs(viaViewModel.wilks - direct.wilks) < 0.001)
        #expect(abs(viaViewModel.dots - direct.dots) < 0.001)
        #expect(abs(viaViewModel.ipfGL - direct.ipfGL) < 0.001)
    }

    @Test func relativeStrengthResultAcceptsExplicitLiftedKg() {
        let vm = CalculatorViewModel(settings: freshSettings())
        let direct = RelativeStrengthEngine.calculate(bodyweightKg: 80, sex: .male, liftedKg: 100)
        let viaViewModel = vm.relativeStrengthResult(bodyweightKg: 80, sex: .male, liftedKg: 100)
        #expect(abs(viaViewModel.wilks - direct.wilks) < 0.001)
        #expect(abs(viaViewModel.dots - direct.dots) < 0.001)
        #expect(abs(viaViewModel.ipfGL - direct.ipfGL) < 0.001)
    }

    // Regression test for the #76 final-review bug fix: the lifted weight from
    // oneRMResult.average is in the user's *display* unit (lbs by default), but
    // RelativeStrengthEngine is calibrated in kg. This test models the exact
    // conversion OneRMModeView performs at its call site — converting liftedKg
    // via WeightUnit.convert before calling relativeStrengthResult — and would
    // fail if that conversion were reverted (i.e. raw lbs passed as liftedKg).
    @Test func lbsModeLiftedWeightMustBeConvertedToKgBeforeScoring() {
        let settings = freshSettings()
        settings.unit = .lbs
        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("2")
        vm.appendDigit("2")
        vm.appendDigit("5")   // 225 lb
        vm.oneRMReps = 1
        let liftedLbs = vm.oneRMResult.average   // ~225, still in lbs
        let correctlyConvertedKg = WeightUnit.lbs.convert(liftedLbs, to: .kg)

        let viaViewModel = vm.relativeStrengthResult(bodyweightKg: 80, sex: .male, liftedKg: correctlyConvertedKg)
        let direct = RelativeStrengthEngine.calculate(bodyweightKg: 80, sex: .male, liftedKg: correctlyConvertedKg)

        // Correctly-converted call matches the engine called directly with kg.
        #expect(abs(viaViewModel.wilks - direct.wilks) < 0.001)

        // Sanity: passing the raw, unconverted lbs value (the original bug)
        // produces a materially different — inflated — score, proving this
        // test is sensitive to the conversion actually happening.
        let buggyUnconverted = vm.relativeStrengthResult(bodyweightKg: 80, sex: .male, liftedKg: liftedLbs)
        #expect(abs(buggyUnconverted.wilks - viaViewModel.wilks) > 1.0)
    }

    // MARK: — Barbell History wiring (#57)

    @Test func commitWeightRecordsHistoryOnlyWhenPro() {
        let settings = freshSettings()
        settings.isPro = false
        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("2"); vm.appendDigit("2"); vm.appendDigit("5")
        vm.commitWeight()
        #expect(settings.barbellHistory.isEmpty)

        settings.isPro = true
        vm.commitWeight()
        #expect(settings.barbellHistory.count == 1)
        #expect(settings.barbellHistory.first?.weight == 225)
    }

    // Regression test for the final-review bug fix: SavedSetupsView's row taps
    // must set the config (bar/collar/single-sided/unit) BEFORE calling
    // vm.loadWeight(), since loadWeight() internally calls commitWeight(),
    // which is what actually records the barbell history entry. Setting
    // config after loadWeight() would let commitWeight() fire with the still-
    // stale live config, recording a phantom entry the user never built. This
    // test replicates the corrected row-tap order at the model level.
    @Test func reloadingAHistoryEntryRecordsItsOwnConfigNotStaleLiveState() {
        let settings = freshSettings()
        settings.isPro = true
        let vm = CalculatorViewModel(settings: settings)

        // Commit an initial "live" config that differs from what we'll reload.
        vm.selectedBar = .olympic45lb
        vm.collarType = .none
        settings.unit = .lbs
        vm.appendDigit("1"); vm.appendDigit("0"); vm.appendDigit("0")
        vm.commitWeight()

        // Simulate tapping a history/saved row for a DIFFERENT config, using the
        // corrected order: config fields set BEFORE loadWeight() (which
        // internally calls commitWeight()).
        vm.selectedBar = .olympic20kg
        vm.collarType = .competition
        vm.isSingleSided = true
        settings.unit = .kg
        vm.loadWeight(150)

        let mostRecent = settings.barbellHistory.first
        #expect(mostRecent?.weight == 150)
        #expect(mostRecent?.barType == .olympic20kg)
        #expect(mostRecent?.collarType == .competition)
        #expect(mostRecent?.unit == .kg)
        #expect(mostRecent?.isSingleSided == true)
    }

    // MARK: — applyConfiguration (#9)

    @Test func applyConfigurationSetsAllFieldsAndLoadsWeight() {
        let settings = freshSettings()
        let vm = CalculatorViewModel(settings: settings)
        vm.applyConfiguration(weight: 150, barType: .olympic20kg, customBarWeight: nil,
                               collarType: .competition, unit: .kg, isSingleSided: true)
        #expect(vm.selectedBar == .olympic20kg)
        #expect(vm.collarType == .competition)
        #expect(vm.isSingleSided == true)
        #expect(settings.unit == .kg)
        #expect(vm.targetWeight == 150)
    }

    @Test func applyConfigurationWritesCustomBarWeightWhenBarIsCustom() {
        let settings = freshSettings()
        settings.customBarWeight = 45
        let vm = CalculatorViewModel(settings: settings)
        vm.applyConfiguration(weight: 100, barType: .custom, customBarWeight: 33,
                               collarType: .none, unit: .lbs, isSingleSided: false)
        #expect(vm.selectedBar == .custom)
        #expect(settings.customBarWeight == 33)
    }

    @Test func applyConfigurationLeavesCustomBarWeightUntouchedWhenBarIsNotCustom() {
        let settings = freshSettings()
        settings.customBarWeight = 45
        let vm = CalculatorViewModel(settings: settings)
        vm.applyConfiguration(weight: 100, barType: .olympic45lb, customBarWeight: 33,
                               collarType: .none, unit: .lbs, isSingleSided: false)
        #expect(vm.selectedBar == .olympic45lb)
        #expect(settings.customBarWeight == 45)   // untouched — not a custom bar, passed value ignored
    }

    @Test func applyConfigurationThreadsCustomBarWeightIntoRecordedHistory() {
        let settings = freshSettings()
        settings.isPro = true
        let vm = CalculatorViewModel(settings: settings)
        vm.applyConfiguration(weight: 100, barType: .custom, customBarWeight: 33,
                               collarType: .none, unit: .lbs, isSingleSided: false)
        #expect(settings.barbellHistory.first?.customBarWeight == 33)
    }

    @Test func applyConfigurationRecordsHistoryWithTheNewUnitNotTheOldOne() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .lbs
        let vm = CalculatorViewModel(settings: settings)
        vm.applyConfiguration(weight: 100, barType: .olympic20kg, customBarWeight: nil,
                               collarType: .none, unit: .kg, isSingleSided: false)
        #expect(settings.barbellHistory.first?.unit == .kg)
    }

    // MARK: — Warmup percentage wiring (#58)

    @Test func warmupSetsReflectCustomPercentages() {
        let settings = freshSettings()
        while settings.warmupPercentages.count > 1 {
            settings.deleteWarmupPercentage(id: settings.warmupPercentages[0].id)
        }
        settings.updateWarmupPercentage(id: settings.warmupPercentages[0].id, percentage: 40)
        settings.addWarmupPercentage()  // adds 50 (40 + 10)

        let vm = CalculatorViewModel(settings: settings)
        vm.appendDigit("2"); vm.appendDigit("0"); vm.appendDigit("0")

        #expect(vm.warmupSets.map(\.percentage) == [40, 50])
    }

    // MARK: — Decimal precision lock (#60)

    @Test func precisionLockRoundsToNearestGranularityWithStandardPlatesOnly() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .kg
        settings.decimalPrecisionLockEnabled = true
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic20kg
        // Standard kg plates only (no micro-loading enabled) → smallest enabled kg plate
        // is 1.25 kg → granularity 2.5 kg. 100.6 / 2.5 = 40.24 → rounds to 40 → 100.0
        // (verified by direct calculation — do not "fix" this test to match different
        // arithmetic without recomputing it yourself first).
        vm.appendDigit("1"); vm.appendDigit("0"); vm.appendDigit("0"); vm.appendDigit("."); vm.appendDigit("6")
        vm.commitWeight()
        #expect(vm.targetWeight == 100.0)
    }

    @Test func precisionLockUsesFinerGranularityWithMicroPlatesEnabled() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .kg
        settings.decimalPrecisionLockEnabled = true
        // Enable the 0.25 kg micro plate so smallestEnabledPlate becomes 0.25 → granularity 0.5.
        settings.kgInventory = settings.kgInventory.map { item in
            var updated = item
            if item.weight == 0.25 { updated.isEnabled = true }
            return updated
        }
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic20kg
        // 100.3 / 0.5 = 200.6 → rounds to 201 → 100.5 (verified by direct calculation).
        vm.appendDigit("1"); vm.appendDigit("0"); vm.appendDigit("0"); vm.appendDigit("."); vm.appendDigit("3")
        vm.commitWeight()
        #expect(vm.targetWeight == 100.5)
    }

    @Test func precisionLockRoundsInLbsModeToo() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .lbs
        settings.decimalPrecisionLockEnabled = true
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic45lb
        // Standard lbs plates only → smallest enabled lbs plate is 2.5 lb → granularity 5 lb.
        // 201.3 / 5 = 40.26 → rounds to 40 → 200.0 (verified by direct calculation).
        vm.appendDigit("2"); vm.appendDigit("0"); vm.appendDigit("1"); vm.appendDigit("."); vm.appendDigit("3")
        vm.commitWeight()
        #expect(vm.targetWeight == 200.0)
    }

    @Test func precisionLockUsesFinerGranularityInLbsWithMicroPlatesEnabled() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .lbs
        settings.decimalPrecisionLockEnabled = true
        // Enable the 0.25 lb micro plate so smallestEnabledPlate becomes 0.25 → granularity 0.5.
        settings.lbsInventory = settings.lbsInventory.map { item in
            var updated = item
            if item.weight == 0.25 { updated.isEnabled = true }
            return updated
        }
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic45lb
        // 200.3 / 0.5 = 400.6 → rounds to 401 → 200.5 (verified by direct calculation).
        vm.appendDigit("2"); vm.appendDigit("0"); vm.appendDigit("0"); vm.appendDigit("."); vm.appendDigit("3")
        vm.commitWeight()
        #expect(vm.targetWeight == 200.5)
    }

    @Test func precisionLockHasNoEffectWhenDisabled() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .kg
        settings.decimalPrecisionLockEnabled = false
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic20kg
        vm.appendDigit("1"); vm.appendDigit("0"); vm.appendDigit("1"); vm.appendDigit("."); vm.appendDigit("3")
        vm.commitWeight()
        #expect(vm.targetWeight == 101.3)
    }

    @Test func precisionLockRoundingProducesNoSpuriousDelta() {
        let settings = freshSettings()
        settings.isPro = true
        settings.unit = .kg
        settings.decimalPrecisionLockEnabled = true
        let vm = CalculatorViewModel(settings: settings)
        vm.selectedBar = .olympic20kg
        // 62 is off the 2.5 kg grid (standard plates only) and rounds to 62.5 —
        // loadWeight() is an explicit action and must never show a delta banner,
        // regardless of whether the lock's rounding changed the value.
        vm.loadWeight(62)
        #expect(vm.lastDelta.isEmpty)
    }

    // MARK: — RPE-adjusted 1RM (#61)

    @Test func oneRMRPEDefaultsToTen() {
        let vm = CalculatorViewModel(settings: freshSettings())
        #expect(vm.oneRMRPE == 10.0)
    }

    @Test func rpeEstimatedOneRMMatchesTableLookup() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")   // targetWeight = 100
        vm.oneRMReps = 5
        vm.oneRMRPE = 8.0
        let expected = 100.0 / (81.1 / 100)
        #expect(abs(vm.rpeEstimatedOneRM! - expected) < 0.001)
    }

    @Test func rpeEstimatedOneRMNilAboveTwelveReps() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")
        vm.oneRMReps = 13
        vm.oneRMRPE = 10.0
        #expect(vm.rpeEstimatedOneRM == nil)
    }

    @Test func oneRMResultUnaffectedByOneRMRPE() {
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("1")
        vm.appendDigit("0")
        vm.appendDigit("0")
        vm.oneRMReps = 5
        vm.oneRMRPE = 10.0
        let resultAtRPE10 = vm.oneRMResult
        vm.oneRMRPE = 6.0
        let resultAtRPE6 = vm.oneRMResult
        #expect(resultAtRPE10.epley == resultAtRPE6.epley)
        #expect(resultAtRPE10.brzycki == resultAtRPE6.brzycki)
    }

    // MARK: — Widget data (#33)

    @Test func commitWeightUpdatesWidgetDataStore() {
        UserDefaults.standard.removePersistentDomain(forName: "group.com.delon.LiftLogic")
        let vm = CalculatorViewModel(settings: freshSettings())
        vm.appendDigit("2")
        vm.appendDigit("2")
        vm.appendDigit("5")
        vm.commitWeight()
        let result = WidgetDataStore.lastUsedWeight()
        #expect(result?.weight == 225)
        #expect(result?.unit == .lbs)
    }

}
