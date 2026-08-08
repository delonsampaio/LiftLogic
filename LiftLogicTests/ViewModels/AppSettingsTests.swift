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

    // MARK: — Rest timer presets (#81)

    /// Sets specific UserDefaults keys on a clean domain, then builds AppSettings.
    private func settingsWith(_ configure: (UserDefaults) -> Void) -> AppSettings {
        let ud = UserDefaults.standard
        ud.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
        configure(ud)
        return AppSettings()
    }

    @Test func migratesLegacyCustomTimerIntoOnePreset() {
        let s = settingsWith { $0.set(240, forKey: "customTimerSeconds") }
        #expect(s.restTimerPresets.count == 1)
        #expect(s.restTimerPresets.first?.seconds == 240)
        #expect(s.restTimerPresets.first?.name == "Custom")
    }

    @Test func noPresetsWhenNoLegacyCustom() {
        let s = settingsWith { _ in }
        #expect(s.restTimerPresets.isEmpty)
    }

    @Test func doesNotReseedAfterPresetsPersisted() {
        // Presets key present but empty → user cleared them; a legacy custom must NOT reseed.
        let s = settingsWith {
            $0.set(240, forKey: "customTimerSeconds")
            $0.set(try! JSONEncoder().encode([RestTimerPreset]()), forKey: "restTimerPresetsJSON")
        }
        #expect(s.restTimerPresets.isEmpty)
    }

    @Test func addTimerPresetAppends() {
        let s = settingsWith { _ in }
        s.addTimerPreset(name: "Heavy", seconds: 300)
        #expect(s.restTimerPresets.map(\.name) == ["Heavy"])
        #expect(s.restTimerPresets.first?.seconds == 300)
    }

    @Test func addTimerPresetClampsSecondsAndLabelsBlankName() {
        let s = settingsWith { _ in }
        s.addTimerPreset(name: "   ", seconds: 5)   // below floor, blank name
        #expect(s.restTimerPresets.first?.seconds == 15)
        #expect(s.restTimerPresets.first?.name == "15s")
    }

    @Test func updateTimerPresetReplacesById() {
        let s = settingsWith { _ in }
        s.addTimerPreset(name: "Heavy", seconds: 300)
        let original = s.restTimerPresets[0]
        s.updateTimerPreset(RestTimerPreset(id: original.id, name: "Max", seconds: 360))
        #expect(s.restTimerPresets.count == 1)
        #expect(s.restTimerPresets[0].name == "Max")
        #expect(s.restTimerPresets[0].seconds == 360)
    }

    @Test func deleteTimerPresetRemovesById() {
        let s = settingsWith { _ in }
        s.addTimerPreset(name: "Heavy", seconds: 300)
        let id = s.restTimerPresets[0].id
        s.deleteTimerPreset(id: id)
        #expect(s.restTimerPresets.isEmpty)
    }

    @Test func durationLabelFormats() {
        #expect(restTimerDurationLabel(45) == "45s")
        #expect(restTimerDurationLabel(120) == "2m")
        #expect(restTimerDurationLabel(150) == "2:30")
    }

    // MARK: — Sex (#76)

    @Test func sexDefaultsToNilWhenUnset() {
        let s = freshSettings()
        #expect(s.sex == nil)
    }

    @Test func sexPersistsAcrossRelaunch() {
        let s = freshSettings()
        s.sex = .female
        let reloaded = AppSettings()
        #expect(reloaded.sex == .female)
    }
}
