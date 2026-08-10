import Testing
import Foundation
@testable import LiftLogic

// @MainActor + .serialized: this suite mutates the App Group UserDefaults suite that
// CalculatorViewModel.commitWeight() also writes to on every commit. CalculatorViewModelTests
// (which calls commitWeight() dozens of times) is @MainActor too, so putting this suite on the
// same actor serializes it against that suite instead of racing on a different executor —
// .serialized alone only orders tests within this one suite, it doesn't prevent cross-suite races.
@MainActor
@Suite("WidgetDataStore", .serialized)
struct WidgetDataStoreTests {
    private func freshStore() {
        UserDefaults.standard.removePersistentDomain(forName: "group.com.delon.LiftLogic")
    }

    @Test func recordAndReadRoundTrips() {
        freshStore()
        WidgetDataStore.recordLastUsedWeight(225.0, unit: .lbs)
        let result = WidgetDataStore.lastUsedWeight()
        #expect(result?.weight == 225.0)
        #expect(result?.unit == .lbs)
    }

    @Test func returnsNilBeforeAnythingRecorded() {
        freshStore()
        #expect(WidgetDataStore.lastUsedWeight() == nil)
    }

    @Test func recordOverwritesPreviousValue() {
        freshStore()
        WidgetDataStore.recordLastUsedWeight(225.0, unit: .lbs)
        WidgetDataStore.recordLastUsedWeight(100.0, unit: .kg)
        let result = WidgetDataStore.lastUsedWeight()
        #expect(result?.weight == 100.0)
        #expect(result?.unit == .kg)
    }
}
