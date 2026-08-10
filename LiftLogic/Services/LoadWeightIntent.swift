import AppIntents
import UIKit

struct LoadWeightIntent: AppIntent {
    static var title: LocalizedStringResource = "Load Weight"
    static var description = IntentDescription("Load a weight into LiftLogic's calculator.")
    static var openAppWhenRun = true

    @Parameter(title: "Weight")
    var weight: Double

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard weight > 0, let url = Self.calcURL(for: weight) else {
            return .result(dialog: "That doesn't look like a valid weight.")
        }
        await UIApplication.shared.open(url)
        let unitSymbol = UserDefaults.standard.string(forKey: "unit") ?? "lbs"
        return .result(dialog: "Loaded \(weight.formatted()) \(unitSymbol)")
    }

    static func calcURL(for weight: Double) -> URL? {
        URL(string: "liftlogic://calc?weight=\(weight)")
    }
}

struct LiftLogicShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LoadWeightIntent(),
            phrases: ["Load a weight in \(.applicationName)"],
            shortTitle: "Load Weight",
            systemImageName: "scalemass"
        )
    }
}
