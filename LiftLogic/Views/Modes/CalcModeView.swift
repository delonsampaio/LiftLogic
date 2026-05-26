import SwiftUI

struct CalcModeView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    @State private var commitTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 12) {

            // ── Info zone ────────────────────────────────────────────────
            // EmptyState and plate breakdown share this slot so the +/−
            // row and numpad never move when content switches.
            // minHeight matches a typical single-row breakdown so there is
            // no height change for the most common case.
            ZStack {
                if vm.targetWeight == 0 {
                    EmptyStateView()
                        .transition(.opacity)
                }
                if vm.targetWeight > 0 && !vm.plateResult.platesPerSide.isEmpty {
                    plateBreakdownView
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 52)
            .animation(.easeInOut(duration: 0.2), value: vm.targetWeight > 0)

            // ── Add / remove delta ───────────────────────────────────────
            // Appears while the user is editing an already-committed weight,
            // showing exactly which plates to add or pull per side.
            let delta = vm.plateDelta
            if !delta.isEmpty {
                PlateDeltaBannerView(delta: delta, unit: settings.unit)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }

            // ── Increment row + recent weights ───────────────────────────
            // Recent weight chips live between the − and + buttons so they
            // occupy a slot that already exists rather than adding a new row.
            // The row height is defined by the button icons — chips just fill
            // the available space in the middle.
            HStack(spacing: 12) {
                Button {
                    vm.decrement()
                    HapticManager.shared.quickIncrement()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(ThemeTokens.textSecondary)
                }
                .accessibilityLabel("Decrease weight")

                // Chips scroll horizontally between the two buttons.
                // When there are no chips the space is simply empty.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.recentWeights, id: \.self) { weight in
                            recentWeightChip(weight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

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

            // ── Numpad ───────────────────────────────────────────────────
            NumpadView(vm: vm)
                .padding(.horizontal)
        }
        .animation(.easeInOut(duration: 0.2), value: vm.plateDelta.isEmpty)
        .onChange(of: vm.targetWeight) { _, _ in
            commitTask?.cancel()
            commitTask = Task {
                try? await Task.sleep(for: .seconds(1.2))
                if !Task.isCancelled { vm.commitWeight() }
            }
        }
    }

    // MARK: - Recent weight chip

    @ViewBuilder
    private func recentWeightChip(_ weight: Double) -> some View {
        Button {
            vm.loadWeight(weight)
            HapticManager.shared.numpadKey()
        } label: {
            Text(weight.weightStringPrecise)
                .font(sizeClass == .regular ? .subheadline.weight(.medium) : .footnote.weight(.medium))
                .monospaced()
                .foregroundStyle(ThemeTokens.textSecondary)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 6 * scale)
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

    // MARK: - Plate breakdown

    // ≤3 types → single centred row.  >3 types → 3-column grid (wraps to row 2).
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
                .frame(width: 10 * scale, height: 10 * scale)
            Text("\(totalCount)×\(group.weight.weightString)")
                .font(sizeClass == .regular ? .title3.weight(.bold) : .body.weight(.bold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
    }
}
