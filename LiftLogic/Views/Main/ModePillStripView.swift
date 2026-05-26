import SwiftUI

struct ModePillStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    @Binding var showPaywall: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppMode.allCases, id: \.self) { mode in
                Button {
                    onPillTap(mode)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 10, weight: .semibold))
                        Text(mode.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(vm.currentMode == mode ? ThemeTokens.accent : ThemeTokens.textMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background {
                        if vm.currentMode == mode {
                            Capsule()
                                .fill(ThemeTokens.accent.opacity(0.18))
                                .overlay(Capsule().strokeBorder(ThemeTokens.accent.opacity(0.4), lineWidth: 1))
                        } else {
                            Capsule()
                                .glassEffect()
                        }
                    }
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: vm.currentMode)
            }
        }
        .padding(.horizontal)
    }

    private func onPillTap(_ mode: AppMode) {
        if mode.requiresPro && !settings.isPro {
            showPaywall = true
        } else {
            HapticManager.shared.modeSwitch()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                vm.currentMode = mode
            }
        }
    }
}
