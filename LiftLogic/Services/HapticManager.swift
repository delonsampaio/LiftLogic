import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    func numpadKey() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func modeSwitch() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func plateLarge() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    func plateMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func plateUndo() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func quickIncrement() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func swipeReset() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func timerComplete() {
        Task {
            let gen = UIImpactFeedbackGenerator(style: .heavy)
            for _ in 0..<3 {
                gen.impactOccurred()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}
