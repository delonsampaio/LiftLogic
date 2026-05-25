import SwiftUI

struct ReverseModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Total — clean, no cramped summary text
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(ThemeTokens.textMuted)
                    Text("\(formatWeight(vm.reverseTotal)) \(settings.unit.symbol)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(ThemeTokens.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: vm.reverseTotal)
                }
                Spacer()
            }
            .padding(.horizontal)

            // Plate rack grid
            PlateRackView(
                inventory: settings.activeInventory,
                unit: settings.unit
            ) { plate in
                vm.addPlate(plate)
                let isHeavy = (settings.unit == .lbs ? plate.weight : WeightUnit.kg.convert(plate.weight, to: .lbs)) >= 45
                isHeavy ? HapticManager.shared.plateLarge() : HapticManager.shared.plateMedium()
            }

            // Plate summary pill — sits between rack and Undo, only shows when plates are added
            if !vm.reversePlateStack.isEmpty {
                plateSummaryPill
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Undo — circular disc, matches the plate-tool aesthetic
            HStack {
                Spacer()
                Button {
                    vm.undoLastPlate()
                    HapticManager.shared.plateUndo()
                } label: {
                    ZStack {
                        Circle()
                            .fill(vm.reversePlateStack.isEmpty
                                  ? Color(white: 0.10)
                                  : ThemeTokens.accent.opacity(0.10))
                        Circle()
                            .strokeBorder(
                                vm.reversePlateStack.isEmpty
                                    ? Color(white: 0.20)
                                    : ThemeTokens.accent.opacity(0.45),
                                lineWidth: 1.5
                            )
                        VStack(spacing: 3) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Undo")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(vm.reversePlateStack.isEmpty
                                         ? ThemeTokens.textMuted
                                         : ThemeTokens.accent)
                    }
                    .frame(width: 68, height: 68)
                }
                .buttonStyle(NumpadButtonStyle())
                .disabled(vm.reversePlateStack.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: vm.reversePlateStack.isEmpty)
                Spacer()
            }
            .padding(.bottom, 4)
        }
    }

    private var plateSummaryPill: some View {
        let grouped = vm.reversePlateStack.reduce(into: [(Double, Int)]()) { acc, plate in
            if let idx = acc.firstIndex(where: { $0.0 == plate.weight }) {
                acc[idx].1 += 1
            } else {
                acc.append((plate.weight, 1))
            }
        }
        let summary = grouped.map { "\($0.1)×\(formatWeight($0.0))" }.joined(separator: "  ·  ")

        return ScrollView(.horizontal, showsIndicators: false) {
            Text(summary)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(ThemeTokens.textSecondary)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(white: 0.14))
                        .overlay(Capsule().strokeBorder(Color(white: 0.28), lineWidth: 0.5))
                )
                .padding(.horizontal)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
