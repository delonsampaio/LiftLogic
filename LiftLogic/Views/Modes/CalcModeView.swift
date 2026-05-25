import SwiftUI

struct CalcModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Empty state
            if vm.targetWeight == 0 {
                EmptyStateView()
                    .transition(.opacity)
            }

            // Smart add delta banner
            if let delta = vm.deltaResult, !delta.platesPerSide.isEmpty {
                smartAddBanner(delta: delta)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

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

            // Plate breakdown — shown before numpad so it's immediately visible
            if !vm.plateResult.platesPerSide.isEmpty {
                plateBreakdownView
                    .padding(.horizontal)
                    .transition(.opacity)
            }

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
        }
        .onChange(of: vm.targetWeight) { _, new in
            if new > 0 { vm.commitWeight() }
        }
    }

    private func smartAddBanner(delta: PlateResult) -> some View {
        let grouped = delta.grouped
        let parts = grouped.map { "\($0.count)× \(formatPlateWeight($0.weight))" }
        let isAdding = vm.isDeltaAdding
        let color = isAdding ? ThemeTokens.accent : ThemeTokens.warningAmber
        return HStack(spacing: 6) {
            Image(systemName: isAdding ? "plus.circle.fill" : "minus.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text("\(isAdding ? "Add" : "Remove") per side: \(parts.joined(separator: " + "))")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal)
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
        return HStack(spacing: 10) {
            ForEach(grouped, id: \.weight) { group in
                HStack(spacing: 5) {
                    Circle()
                        .fill(ThemeTokens.plateColor(for: group.weight, unit: settings.unit))
                        .frame(width: 9, height: 9)
                    Text("\(group.count)× \(formatPlateWeight(group.weight))")
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(ThemeTokens.textPrimary.opacity(0.85))
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func formatPlateWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
