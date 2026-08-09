import SwiftUI

struct QuickToggleStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var containerWidth: CGFloat = 390
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Unit toggle
                toggleChip(
                    title: settings.unit == .lbs ? "lbs" : "kg",
                    isActive: false
                ) {
                    settings.unit = settings.unit == .lbs ? .kg : .lbs
                }

                Divider().frame(height: 20 * scale).opacity(0.3)

                // Bar picker — stripLabel omits weight to keep chip compact on small screens.
                // Full displayName is shown in the menu options below.
                Menu {
                    ForEach(BarType.allCases) { bar in
                        Button(bar == .custom
                               ? "Custom (\(String(format: "%.1f", settings.customBarWeight)) \(settings.unit.symbol))"
                               : bar.displayName) {
                            vm.selectedBar = bar
                        }
                    }
                } label: {
                    toggleChip(
                        title: vm.selectedBar == .custom
                            ? "Custom"
                            : vm.selectedBar.stripLabel,
                        isActive: false,
                        showChevron: true
                    ) {}
                }

                Divider().frame(height: 20 * scale).opacity(0.3)

                // Collar toggle
                toggleChip(title: collarLabel, isActive: vm.collarType != .none) {
                    vm.collarType = vm.collarType.next()
                }

                // Single-sided toggle
                toggleChip(title: "Single Side", isActive: vm.isSingleSided) {
                    vm.isSingleSided.toggle()
                }
            }
            // Centre the strip when it fits; let it scroll when it doesn't.
            // contentMargins (below) adds 16 pt insets inside the scroll region, so we
            // subtract 32 pt here so the logical centre is still the screen centre.
            .frame(minWidth: containerWidth - 32, alignment: .center)
        }
        // contentMargins extends the scrollable area at each edge without widening the frame,
        // which is why .padding(.horizontal) on the HStack was causing clipping.
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(height: 40 * scale)
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { containerWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in containerWidth = w }
            }
        }
    }

    @ViewBuilder
    private func toggleChip(
        title: String,
        isActive: Bool,
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(sizeClass == .regular ? .subheadline.weight(.medium) : .caption.weight(.medium))
                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(sizeClass == .regular ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                }
            }
            .foregroundStyle(isActive ? settings.accentColor : ThemeTokens.textSecondary)
            .padding(.horizontal, 12 * scale)
            .padding(.vertical, 7 * scale)
            .background(
                Capsule()
                    .fill(isActive ? settings.accentColor.opacity(0.15) : Color(white: 0.12))
                    .overlay(Capsule().strokeBorder(
                        isActive ? settings.accentColor.opacity(0.4) : Color(white: 0.2),
                        lineWidth: 1
                    ))
            )
        }
        .buttonStyle(.plain)
    }

    private var collarLabel: String {
        switch vm.collarType {
        case .none:        return "No Collar"
        case .springClip:  return "Spring Clip"
        case .competition: return "Comp Collar"
        }
    }
}

private extension CollarType {
    func next() -> CollarType {
        switch self {
        case .none:        return .springClip
        case .springClip:  return .competition
        case .competition: return .none
        }
    }
}
