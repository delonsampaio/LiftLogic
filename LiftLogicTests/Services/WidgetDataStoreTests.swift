import Testing
import Foundation
@testable import LiftLogic

// Serialized: all tests share the App Group UserDefaults suite as global mutable state, so
// Swift Testing's default parallel execution across test methods would race between them.
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
