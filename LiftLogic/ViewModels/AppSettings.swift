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

    // Pro features
    var bodyWeight: Double {
        didSet { UserDefaults.standard.set(bodyWeight, forKey: "bodyWeight") }
    }
    var recentWeights: [Double] {
        didSet { saveDoubleArray(recentWeights, key: "recentWeights") }
    }
    var savedSetups: [SavedSetup] {
        didSet { saveCodable(savedSetups, key: "savedSetupsJSON") }
    }

    init() {
        let ud = UserDefaults.standard
        unit = WeightUnit(rawValue: ud.string(forKey: "unit") ?? "") ?? .lbs
        defaultBar = BarType(rawValue: ud.string(forKey: "defaultBar") ?? "") ?? .olympic45lb
        customBarWeight = ud.double(forKey: "customBarWeight").nonZero ?? 45.0
        lbsInventory = loadInventory(key: "lbsInventoryJSON") ?? AppSettings.defaultLbs
        kgInventory = loadInventory(key: "kgInventoryJSON") ?? AppSettings.defaultKg
        isPro = ud.bool(forKey: "isPro")
        bodyWeight = ud.double(forKey: "bodyWeight")
        recentWeights = loadDoubleArray(key: "recentWeights") ?? []
        savedSetups = loadCodable([SavedSetup].self, key: "savedSetupsJSON") ?? []
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

    // MARK: — Defaults

    static let defaultLbs: [PlateInventoryItem] = [45, 35, 25, 10, 5, 2.5].map {
        PlateInventoryItem(weight: $0, isEnabled: true)
    }
    static let defaultKg: [PlateInventoryItem] = [25, 20, 15, 10, 5, 2.5, 1.25].map {
        PlateInventoryItem(weight: $0, isEnabled: true)
    }
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
