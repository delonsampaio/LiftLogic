import SwiftUI

struct ModePillStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    @Binding var showPaywall: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geo in
            // iPad: 1.4x. Pro Max (~430pt) and wider phones: 1.0x. Narrower phones: scale down.
            // 390pt (iPhone 16 Pro) is the baseline — pills fit comfortably at 1.0x.
            let pillScale: CGFloat = sizeClass == .regular
                ? 1.4
                : min(1.0, geo.size.width / 390)

            HStack(spacing: 8 * pillScale) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    Button {
                        onPillTap(mode)
                    } label: {
                        HStack(spacing: 4 * pillScale) {
                            Image(systemName: mode.iconName)
                                .font(sizeClass == .regular ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                            Text(mode.displayName)
                                .font(sizeClass == .regular ? .subheadline.weight(.semibold) : .caption.weight(.semibold))
                        }
                        .foregroundStyle(vm.currentMode == mode ? ThemeTokens.accent : ThemeTokens.textMuted)
                        .padding(.horizontal, 12 * pillScale)
                        .padding(.vertical, 8 * pillScale)
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
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .fixedSize(horizontal: false, vertical: true)
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
