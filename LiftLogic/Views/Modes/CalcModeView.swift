import SwiftUI

struct CalcModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Quick increment row
            HStack(spacing: 16) {
                Button {
                    vm.decrement()
                    HapticManager.shared.quickIncrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ThemeTokens.textSecondary)
                }

                Spacer()

                Button {
                    vm.increment()
                    HapticManager.shared.quickIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(ThemeTokens.accent)
                }
            }
            .padding(.horizontal, 24)

            // Recent weights chips
            if !settings.recentWeights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.recentWeights, id: \.self) { weight in
                            recentWeightChip(weight)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Numpad
            NumpadView(vm: vm)
                .padding(.horizontal)

            // Plate breakdown summary
            if !vm.plateResult.platesPerSide.isEmpty {
                plateBreakdownView
                    .padding(.horizontal)
            }
        }
        .onChange(of: vm.targetWeight) { _, new in
            if new > 0 { vm.commitWeight() }
        }
    }

    @ViewBuilder
    private func recentWeightChip(_ weight: Double) -> some View {
        let label = weight.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(weight))"
            : String(format: "%.2f", weight)

        Button {
            vm.loadWeight(weight)
            HapticManager.shared.numpadKey()
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(ThemeTokens.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(white: 0.12))
                        .overlay(Capsule().strokeBorder(Color(white: 0.22), lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                settings.removeRecentWeight(weight)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var plateBreakdownView: some View {
        let grouped = vm.plateResult.grouped
        let parts = grouped.map { "\($0.count)× \(formatPlateWeight($0.weight))" }
        return Text(parts.joined(separator: " · "))
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(ThemeTokens.textMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func formatPlateWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
