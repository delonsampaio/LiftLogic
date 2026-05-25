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

            // Undo — bordered "action" button, visually distinct from plate "data" buttons
            Button {
                vm.undoLastPlate()
                HapticManager.shared.plateUndo()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo Last Plate")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(vm.reversePlateStack.isEmpty ? ThemeTokens.textMuted : ThemeTokens.accent)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(vm.reversePlateStack.isEmpty
                              ? Color.clear
                              : ThemeTokens.accent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    vm.reversePlateStack.isEmpty
                                        ? Color(white: 0.22)
                                        : ThemeTokens.accent.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.reversePlateStack.isEmpty)
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: vm.reversePlateStack.isEmpty)
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

        return HStack {
            Spacer()
            Text(summary)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeTokens.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(white: 0.12))
                        .overlay(Capsule().strokeBorder(Color(white: 0.22), lineWidth: 0.5))
                )
            Spacer()
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
