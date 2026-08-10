import Foundation

/// Shared, App-Group-backed store for the data the Home Screen / Lock Screen widget needs.
/// Deliberately separate from AppSettings (which stays on UserDefaults.standard, not shared with
/// the widget extension process) rather than adding another property there.
enum WidgetDataStore {
    private static let suiteName = "group.com.delon.LiftLogic"
    private static let weightKey = "lastUsedWeight"
    private static let unitKey = "lastUsedUnit"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: suiteName) }

    static func recordLastUsedWeight(_ weight: Double, unit: WeightUnit) {
        defaults?.set(weight, forKey: weightKey)
        defaults?.set(unit.rawValue, forKey: unitKey)
    }

    /// nil when no weight has ever been committed (fresh install).
    static func lastUsedWeight() -> (weight: Double, unit: WeightUnit)? {
        guard let defaults, defaults.object(forKey: weightKey) != nil,
              let unit = WeightUnit(rawValue: defaults.string(forKey: unitKey) ?? "")
        else { return nil }
        return (defaults.double(forKey: weightKey), unit)
    }
}
