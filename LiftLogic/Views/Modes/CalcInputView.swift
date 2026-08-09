import SwiftUI

/// The CALC input cluster: recent-weight chips, −/+ increment row, numpad, and
/// the delta-toast overlay. Extracted so iPad can keep it persistently visible.
struct CalcInputView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var scale: CGFloat { sizeClass == .regular ? 1.4 : 1.0 }

    @State private var commitTask: Task<Void, Never>?
    // Start dismissed so the toast doesn't fire when switching back to CALC with a stale delta.
    @State private var toastDismissed = true
    // Tracks the last commitRevision this view has already reacted to, so a
    // targetWeight change caused by commitWeight() itself (e.g. Decimal
    // Precision Lock rounding the value after a commit) can be told apart
    // from a targetWeight change caused by fresh user typing.
    @State private var lastSeenCommitRevision = 0

    var body: some View {
        VStack(spacing: 12) {
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
                        .foregroundStyle(settings.accentColor)
                }
                .accessibilityLabel("Increase weight")
            }
            .padding(.horizontal, 24)

            NumpadView(vm: vm)
                .padding(.horizontal)
        }
        .overlay(alignment: .bottom) {
            let delta = vm.lastDelta
            let key = delta.map { "\($0.weight)\($0.change)" }.joined()
            if settings.deltaBannerEnabled && !delta.isEmpty && !toastDismissed {
                PlateDeltaBannerView(
                    delta: delta,
                    unit: settings.unit,
                    duration: Double(settings.deltaAutoDismissSeconds),
                    onDismiss: { toastDismissed = true },
                    accentColor: settings.accentColor
                )
                .id(key)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8),
                   value: vm.lastDelta.isEmpty || toastDismissed)
        .onChange(of: vm.targetWeight) { _, _ in
            // A commit already advanced commitRevision since we last recorded it —
            // this targetWeight change was caused by that commit (rounding), not
            // by new typing. Don't reschedule a redundant commit or hide a toast
            // that should stay visible.
            guard vm.commitRevision == lastSeenCommitRevision else { return }
            commitTask?.cancel()
            commitTask = Task {
                try? await Task.sleep(for: .seconds(1.2))
                if !Task.isCancelled { vm.commitWeight() }
            }
            toastDismissed = true
        }
        .onChange(of: vm.commitRevision) { _, newValue in
            lastSeenCommitRevision = newValue
            if !vm.lastDelta.isEmpty {
                toastDismissed = false
            }
        }
    }

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
}
