import SwiftUI

// Temporary stubs — replaced in Tasks 16–21

struct WarmupModeView: View {
    let vm: CalculatorViewModel; let settings: AppSettings
    var body: some View { Text("Warmup — Pro").foregroundStyle(.white) }
}
struct OneRMModeView: View {
    let vm: CalculatorViewModel; let settings: AppSettings
    var body: some View { Text("1RM — Pro").foregroundStyle(.white) }
}
struct ReverseModeView: View {
    let vm: CalculatorViewModel; let settings: AppSettings
    var body: some View { Text("Reverse — Pro").foregroundStyle(.white) }
}
struct ProPaywallView: View {
    let settings: AppSettings
    var body: some View { Text("Pro Paywall").foregroundStyle(.white) }
}
struct SettingsView: View {
    let settings: AppSettings; let vm: CalculatorViewModel
    var body: some View { Text("Settings").foregroundStyle(.white) }
}
