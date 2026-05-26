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

}
