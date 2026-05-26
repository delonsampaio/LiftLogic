import SwiftUI

struct ModePillStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    @Binding var showPaywall: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    var body: some View {
        HStack(spacing: 8 * scale) {
            ForEach(AppMode.allCases, id: \.self) { mode in
                Button {
                    onPillTap(mode)
                } label: {
                    HStack(spacing: 4 * scale) {
                        Image(systemName: mode.iconName)
                            .font(sizeClass == .regular ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                        Text(mode.displayName)
                            .font(sizeClass == .regular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                    }
                    .foregroundStyle(vm.currentMode == mode ? ThemeTokens.accent : ThemeTokens.textMuted)
                    .padding(.horizontal, 12 * scale)
                    .padding(.vertical, 8 * scale)
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
