import SwiftUI

struct ReverseModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Current total
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
                // Plates added summary
                if !vm.reversePlateStack.isEmpty {
                    let grouped = vm.reversePlateStack.reduce(into: [(Double, Int)]()) { acc, plate in
                        if let idx = acc.firstIndex(where: { $0.0 == plate.weight }) {
                            acc[idx].1 += 1
                        } else {
                            acc.append((plate.weight, 1))
                        }
                    }
                    Text(grouped.prefix(3).map { "\($0.1)×\(formatWeight($0.0))" }.joined(separator: " "))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(ThemeTokens.textMuted)
                }
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

            // Undo button
            Button {
                vm.undoLastPlate()
                HapticManager.shared.plateUndo()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Undo Last Plate")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(vm.reversePlateStack.isEmpty ? ThemeTokens.textMuted : ThemeTokens.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.13)))
            }
            .buttonStyle(.plain)
            .disabled(vm.reversePlateStack.isEmpty)
            .padding(.horizontal)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
