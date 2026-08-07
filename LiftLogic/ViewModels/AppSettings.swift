import Foundation
import Observation

@Observable
final class AppSettings {
    // Unit system
    var unit: WeightUnit {
        didSet { UserDefaults.standard.set(unit.rawValue, forKey: "unit") }
    }

    // Bar config
    var defaultBar: BarType {
        didSet { UserDefaults.standard.set(defaultBar.rawValue, forKey: "defaultBar") }
    }
    var customBarWeight: Double {
        didSet { UserDefaults.standard.set(customBarWeight, forKey: "customBarWeight") }
    }

    // Plate inventory (stored as JSON string)
    var lbsInventory: [PlateInventoryItem] {
        didSet { saveInventory(lbsInventory, key: "lbsInventoryJSON") }
    }
    var kgInventory: [PlateInventoryItem] {
        didSet { saveInventory(kgInventory, key: "kgInventoryJSON") }
    }

    // Pro
    var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: "isPro") }
    }

    // App engagement — used for review prompt
    var successfulCalculationCount: Int {
        didSet { UserDefaults.standard.set(successfulCalculationCount, forKey: "successfulCalculationCount") }
    }

    // Pro features
    var bodyWeight: Double {
        didSet { UserDefaults.standard.set(bodyWeight, forKey: "bodyWeight") }
    }
    /// User's preferred custom rest timer duration in seconds. 0 = not yet set.
    var customTimerSeconds: Int {
        didSet { UserDefaults.standard.set(customTimerSeconds, forKey: "customTimerSeconds") }
    }
    // Recent weights — stored per unit so lbs values never surface as kg (or vice versa).
    private var lbsRecentWeights: [Double] {
        didSet { saveDoubleArray(lbsRecentWeights, key: "lbsRecentWeights") }
    }
    private var kgRecentWeights: [Double] {
        didSet { saveDoubleArray(kgRecentWeights, key: "kgRecentWeights") }
    }
    /// Recent weights for the currently-selected unit.
    var recentWeights: [Double] {
        get { unit == .lbs ? lbsRecentWeights : kgRecentWeights }
        set {
            if unit == .lbs { lbsRecentWeights = newValue } else { kgRecentWeights = newValue }
        }
    }
    var savedSetups: [SavedSetup] {
        didSet {
            saveCodable(savedSetups, key: "savedSetupsJSON")
            pushSavedSetupsToCloud()
        }
    }

    /// Named rest-timer presets (Pro). Replaces the legacy single customTimerSeconds.
    var restTimerPresets: [RestTimerPreset] {
        didSet { saveCodable(restTimerPresets, key: "restTimerPresetsJSON") }
    }

    /// Whether the add/remove per-side toast appears when the target weight changes.
    var deltaBannerEnabled: Bool {
        didSet { UserDefaults.standard.set(deltaBannerEnabled, forKey: "deltaBannerEnabled") }
    }

    /// Seconds before the delta toast auto-dismisses. 0 = stay until dismissed manually.
    var deltaAutoDismissSeconds: Int {
        didSet { UserDefaults.standard.set(deltaAutoDismissSeconds, forKey: "deltaAutoDismissSeconds") }
    }

    init() {
        let ud = UserDefaults.standard
        let savedUnit = WeightUnit(rawValue: ud.string(forKey: "unit") ?? "") ?? .lbs
        unit = savedUnit
        defaultBar = BarType(rawValue: ud.string(forKey: "defaultBar") ?? "") ?? .olympic45lb
        customBarWeight = ud.double(forKey: "customBarWeight").nonZero ?? 45.0
        lbsInventory = AppSettings.mergedInventory(saved: loadInventory(key: "lbsInventoryJSON"),
                                                   defaults: AppSettings.defaultLbs)
        kgInventory  = AppSettings.mergedInventory(saved: loadInventory(key: "kgInventoryJSON"),
                                                   defaults: AppSettings.defaultKg)
        isPro = ud.bool(forKey: "isPro")
        successfulCalculationCount = ud.integer(forKey: "successfulCalculationCount")
        bodyWeight = ud.double(forKey: "bodyWeight")
        customTimerSeconds = ud.integer(forKey: "customTimerSeconds")
        // Migrate the pre-1.x single recent-weights list into the active unit's bucket.
        let legacyRecent = loadDoubleArray(key: "recentWeights") ?? []
        lbsRecentWeights = loadDoubleArray(key: "lbsRecentWeights") ?? (savedUnit == .lbs ? legacyRecent : [])
        kgRecentWeights  = loadDoubleArray(key: "kgRecentWeights")  ?? (savedUnit == .kg  ? legacyRecent : [])
        savedSetups = loadCodable([SavedSetup].self, key: "savedSetupsJSON") ?? []
        deltaBannerEnabled = ud.object(forKey: "deltaBannerEnabled") as? Bool ?? true
        deltaAutoDismissSeconds = ud.integer(forKey: "deltaAutoDismissSeconds")  // 0 = off
        // Migrate the legacy single custom timer into one named preset on first run only.
        // If the presets key is present (even as []), the user has curated them — don't reseed.
        let legacyCustomTimerSeconds = ud.integer(forKey: "customTimerSeconds")
        if let savedPresets = loadCodable([RestTimerPreset].self, key: "restTimerPresetsJSON") {
            restTimerPresets = savedPresets
        } else if legacyCustomTimerSeconds > 0 {
            restTimerPresets = [RestTimerPreset(name: "Custom", seconds: legacyCustomTimerSeconds)]
        } else {
            restTimerPresets = []
        }

        // iCloud sync for Saved Setups — adopt remote state if it exists and differs,
        // then keep listening for changes pushed from other devices. Placed last in
        // init() since it calls an instance method, which requires every stored
        // property to already be assigned.
        pullSavedSetupsFromCloud()
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            self?.pullSavedSetupsFromCloud()
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    // MARK: — Derived

    var activeInventory: [PlateInventoryItem] {
        unit == .lbs ? lbsInventory : kgInventory
    }

    // MARK: — Recent Weights

    func addRecentWeight(_ value: Double) {
        var updated = recentWeights.filter { $0 != value }
        updated.insert(value, at: 0)
        recentWeights = Array(updated.prefix(5))
    }

    func removeRecentWeight(_ value: Double) {
        recentWeights.removeAll { $0 == value }
    }

    // MARK: — Saved Setups (Pro)

    func saveSetup(_ setup: SavedSetup) {
        savedSetups.append(setup)
    }

    func deleteSetup(id: UUID) {
        savedSetups.removeAll { $0.id == id }
    }

    // MARK: — Saved Setups iCloud sync

    /// Set while applying a remote change to `savedSetups`, so the resulting
    /// `didSet` doesn't push the same data right back to the cloud.
    private var isApplyingRemoteSavedSetups = false

    /// Encodes and pushes `savedSetups` to the iCloud key-value store, unless
    /// this change originated from a cloud pull.
    private func pushSavedSetupsToCloud() {
        guard !isApplyingRemoteSavedSetups else { return }
        guard let data = try? JSONEncoder().encode(savedSetups) else { return }
        NSUbiquitousKeyValueStore.default.set(data, forKey: "savedSetupsJSON")
    }

    /// Reads the iCloud key-value store and adopts it locally if present and different.
    private func pullSavedSetupsFromCloud() {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: "savedSetupsJSON"),
              let remote = try? JSONDecoder().decode([SavedSetup].self, from: data),
              remote != savedSetups else { return }
        isApplyingRemoteSavedSetups = true
        savedSetups = remote
        isApplyingRemoteSavedSetups = false
    }

    // MARK: — Rest Timer Presets (Pro)

    func addTimerPreset(name: String, seconds: Int) {
        restTimerPresets.append(makePreset(id: UUID(), name: name, seconds: seconds))
    }

    func updateTimerPreset(_ preset: RestTimerPreset) {
        guard let idx = restTimerPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        restTimerPresets[idx] = makePreset(id: preset.id, name: preset.name, seconds: preset.seconds)
    }

    func deleteTimerPreset(id: UUID) {
        restTimerPresets.removeAll { $0.id == id }
    }

    /// Clamps to a 15s floor and falls back to a duration label when the name is blank.
    private func makePreset(id: UUID, name: String, seconds: Int) -> RestTimerPreset {
        let safeSeconds = max(15, seconds)
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let label = trimmed.isEmpty ? restTimerDurationLabel(safeSeconds) : trimmed
        return RestTimerPreset(id: id, name: label, seconds: safeSeconds)
    }

    // MARK: — Inventory migration

    /// Keeps the user's saved inventory (preserving enabled/quantity state) and
    /// appends any plates from `defaults` whose weight isn't already present.
    /// This ensures new plate weights added in future builds appear for existing users.
    static func mergedInventory(saved: [PlateInventoryItem]?,
                                defaults: [PlateInventoryItem]) -> [PlateInventoryItem] {
        guard let saved else { return defaults }
        let savedWeights = Set(saved.map(\.weight))
        let newPlates = defaults.filter { !savedWeights.contains($0.weight) }
        return saved + newPlates
    }

    // MARK: — Defaults

    static let defaultLbs: [PlateInventoryItem] = {
        let heavy:    [Double] = [100, 55]                   // non-standard — disabled by default
        let standard: [Double] = [45, 35, 25, 10, 5, 2.5]
        let micro:    [Double] = [1.25, 1.0, 0.75, 0.5, 0.25]
        return heavy.map    { PlateInventoryItem(weight: $0, isEnabled: false) }
             + standard.map { PlateInventoryItem(weight: $0, isEnabled: true) }
             + micro.map    { PlateInventoryItem(weight: $0, isEnabled: false) }
    }()

    static let defaultKg: [PlateInventoryItem] = {
        let heavy:    [Double] = [50]                        // non-standard — disabled by default
        let standard: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
        let micro:    [Double] = [2.0, 1.5, 1.0, 0.5, 0.25]
        return heavy.map    { PlateInventoryItem(weight: $0, isEnabled: false) }
             + standard.map { PlateInventoryItem(weight: $0, isEnabled: true) }
             + micro.map    { PlateInventoryItem(weight: $0, isEnabled: false) }
    }()
}

// MARK: — Private persistence helpers

private func loadInventory(key: String) -> [PlateInventoryItem]? {
    loadCodable([PlateInventoryItem].self, key: key)
}

private func saveInventory(_ items: [PlateInventoryItem], key: String) {
    saveCodable(items, key: key)
}

private func loadDoubleArray(key: String) -> [Double]? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode([Double].self, from: data)
}

private func saveDoubleArray(_ array: [Double], key: String) {
    let data = try? JSONEncoder().encode(array)
    UserDefaults.standard.set(data, forKey: key)
}

private func loadCodable<T: Decodable>(_ type: T.Type, key: String) -> T? {
    guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
}

private func saveCodable<T: Encodable>(_ value: T, key: String) {
    let data = try? JSONEncoder().encode(value)
    UserDefaults.standard.set(data, forKey: key)
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
