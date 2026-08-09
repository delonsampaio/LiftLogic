import SwiftUI

struct ModePillStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    @Binding var showPaywall: Bool

    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var containerWidth: CGFloat = 390

    var body: some View {
        pillRow(pillScale: pillScale)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, w in containerWidth = w }
                }
            }
            .padding(.horizontal)
    }

    private var pillScale: CGFloat {
        sizeClass == .regular ? 1.4 : min(1.0, containerWidth / 390)
    }

    private func pillRow(pillScale: CGFloat) -> some View {
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
                    .foregroundStyle(vm.currentMode == mode ? settings.accentColor : ThemeTokens.textMuted)
                    .padding(.horizontal, 12 * pillScale)
                    .padding(.vertical, 8 * pillScale)
                    .background {
                        if vm.currentMode == mode {
                            Capsule()
                                .fill(settings.accentColor.opacity(0.18))
                                .overlay(Capsule().strokeBorder(settings.accentColor.opacity(0.4), lineWidth: 1))
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
