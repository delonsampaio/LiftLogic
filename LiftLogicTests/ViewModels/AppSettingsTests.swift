import Testing
import Foundation
@testable import LiftLogic

@MainActor
@Suite("AppSettings")
struct AppSettingsTests {

    private func freshSettings() -> AppSettings {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        return AppSettings()
    }

    // MARK: — Recent weights are unit-scoped (bug fix)

    @Test func recentWeightsAreScopedPerUnit() {
        let s = freshSettings()
        s.unit = .lbs
        s.addRecentWeight(225)
        // Switching to kg must not show the 225 lb value as if it were 225 kg.
        s.unit = .kg
        #expect(s.recentWeights.isEmpty)
        s.addRecentWeight(100)
        #expect(s.recentWeights == [100])
        // The lbs list is untouched when we switch back.
        s.unit = .lbs
        #expect(s.recentWeights == [225])
    }

    @Test func recentWeightsCappedAtFiveMostRecentFirst() {
        let s = freshSettings()
        s.unit = .lbs
        for w in [100.0, 105, 110, 115, 120, 125] { s.addRecentWeight(w) }
        #expect(s.recentWeights.count == 5)
        #expect(s.recentWeights.first == 125)          // most-recent first
        #expect(!s.recentWeights.contains(100))        // oldest dropped
    }

    @Test func addRecentWeightDeduplicatesAndPromotes() {
        let s = freshSettings()
        s.unit = .lbs
        s.addRecentWeight(135)
        s.addRecentWeight(225)
        s.addRecentWeight(135)          // re-add existing → moves to front, no dupe
        #expect(s.recentWeights == [135, 225])
    }

    // MARK: — Inventory migration

    @Test func mergedInventoryKeepsSavedStateAndAppendsNewPlates() {
        // Saved inventory is missing a plate the current defaults include.
        let saved = [PlateInventoryItem(weight: 45, isEnabled: false, quantity: 4)]
        let defaults = [
            PlateInventoryItem(weight: 45, isEnabled: true),
            PlateInventoryItem(weight: 25, isEnabled: true)
        ]
        let merged = AppSettings.mergedInventory(saved: saved, defaults: defaults)
        // The user's 45 keeps its disabled/quantity state…
        let fortyFive = merged.first { $0.weight == 45 }
        #expect(fortyFive?.isEnabled == false)
        #expect(fortyFive?.quantity == 4)
        // …and the new 25 is appended.
        #expect(merged.contains { $0.weight == 25 })
        #expect(merged.count == 2)
    }

    @Test func mergedInventoryReturnsDefaultsWhenNothingSaved() {
        let defaults = AppSettings.defaultLbs
        let merged = AppSettings.mergedInventory(saved: nil, defaults: defaults)
        #expect(merged.count == defaults.count)
    }
}
