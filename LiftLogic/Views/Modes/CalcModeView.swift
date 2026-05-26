import SwiftUI

struct CalcModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @State private var commitTask: Task<Void, Never>?

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
                        .font(.largeTitle)
                        .foregroundStyle(ThemeTokens.textSecondary)
                }
                .accessibilityLabel("Decrease weight")

                Spacer()

                Button {
                    vm.increment()
                    HapticManager.shared.quickIncrement()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(ThemeTokens.accent)
                }
                .accessibilityLabel("Increase weight")
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
        .onChange(of: vm.targetWeight) { _, _ in
            commitTask?.cancel()
            commitTask = Task {
                try? await Task.sleep(for: .seconds(1.2))
                if !Task.isCancelled { vm.commitWeight() }
            }
        }
    }

    private func smartAddBanner(delta: PlateResult) -> some View {
        let grouped = delta.grouped
        let parts = grouped.map { "\($0.count)× \($0.weight.weightString)" }
        let isAdding = vm.isDeltaAdding
        let color = isAdding ? ThemeTokens.accent : ThemeTokens.warningAmber
        return HStack(spacing: 6) {
            Image(systemName: isAdding ? "plus.circle.fill" : "minus.circle.fill")
                .font(.footnote)
                .foregroundStyle(color)
            Text("\(isAdding ? "Add" : "Remove") per side: \(parts.joined(separator: " + "))")
                .font(.footnote.weight(.medium))
                .monospaced()
                .foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func recentWeightChip(_ weight: Double) -> some View {
        let label = weight.weightStringPrecise

        Button {
            vm.loadWeight(weight)
            HapticManager.shared.numpadKey()
        } label: {
            Text(label)
                .font(.footnote.weight(.medium))
                .monospaced()
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

    // ≤3 types: single centered row. >3: 3-column grid (wraps to row 2).
    private var plateBreakdownView: some View {
        let grouped = vm.plateResult.grouped
        return Group {
            if grouped.count <= 3 {
                HStack(spacing: 16) {
                    ForEach(grouped, id: \.weight) { group in
                        plateCell(group)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            } else {
                let columns = [
                    GridItem(.flexible(), alignment: .center),
                    GridItem(.flexible(), alignment: .center),
                    GridItem(.flexible(), alignment: .center)
                ]
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(grouped, id: \.weight) { group in
                        plateCell(group)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func plateCell(_ group: (weight: Double, count: Int)) -> some View {
        let totalCount = group.count * (vm.isSingleSided ? 1 : 2)
        return HStack(spacing: 6) {
            Circle()
                .fill(ThemeTokens.plateColor(for: group.weight, unit: settings.unit))
                .frame(width: 10, height: 10)
            Text("\(totalCount)×\(group.weight.weightString)")
                .font(.body.weight(.bold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
    }
}
