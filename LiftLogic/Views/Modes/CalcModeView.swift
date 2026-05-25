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
                    .transition(.opacity)
            }

            // Recent weights chips
            if !settings.recentWeights.isEmpty {
                GeometryReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(settings.recentWeights, id: \.self) { weight in
                                recentWeightChip(weight)
                            }
                        }
                        .frame(minWidth: proxy.size.width, alignment: .center)
                        .padding(.horizontal)
                    }
                }
                .frame(height: 34)
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

    // 3-column grid — centers when ≤3 groups, wraps cleanly for 4–6
    private var plateBreakdownView: some View {
        let grouped = vm.plateResult.grouped
        let columns = [
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center),
            GridItem(.flexible(), alignment: .center)
        ]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(grouped, id: \.weight) { group in
                HStack(spacing: 6) {
                    Circle()
                        .fill(ThemeTokens.plateColor(for: group.weight, unit: settings.unit))
                        .frame(width: 10, height: 10)
                    Text("\(group.count)×\(formatPlateWeight(group.weight))")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(ThemeTokens.textPrimary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatPlateWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
