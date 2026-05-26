import SwiftUI

struct QuickToggleStripView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Unit toggle
                toggleChip(
                    title: settings.unit == .lbs ? "lbs" : "kg",
                    isActive: false
                ) {
                    settings.unit = settings.unit == .lbs ? .kg : .lbs
                }

                Divider().frame(height: 20).opacity(0.3)

                // Bar picker
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
                            ? "Custom bar"
                            : vm.selectedBar.displayName,
                        isActive: false,
                        showChevron: true
                    ) {}
                }

                Divider().frame(height: 20).opacity(0.3)

                // Collar toggle
                toggleChip(title: collarLabel, isActive: vm.collarType != .none) {
                    vm.collarType = vm.collarType.next()
                }

                // Single-sided toggle
                toggleChip(title: "Single Side", isActive: vm.isSingleSided) {
                    vm.isSingleSided.toggle()
                }
            }
            .padding(.horizontal)
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
                    .font(.caption.weight(.medium))
                if showChevron {
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
            }
            .foregroundStyle(isActive ? ThemeTokens.accent : ThemeTokens.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isActive ? ThemeTokens.accent.opacity(0.15) : Color(white: 0.12))
                    .overlay(Capsule().strokeBorder(
                        isActive ? ThemeTokens.accent.opacity(0.4) : Color(white: 0.2),
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
