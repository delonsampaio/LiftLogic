import SwiftUI

/// Floating toast showing plates to add / remove per side.
/// Expands vertically to fit all changes — no horizontal scrolling.
/// When `duration` > 0 shows a draining progress bar and auto-dismisses.
/// When `duration` == 0 stays until the user taps ×.
/// Recreate (change `.id(…)`) when the delta changes to restart the timer.
struct PlateDeltaBannerView: View {
    let delta: [(weight: Double, change: Int)]
    let unit: WeightUnit
    /// Seconds until auto-dismiss. 0 = stay until manually dismissed.
    let duration: Double
    let onDismiss: () -> Void

    @State private var progress: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Title row + dismiss ───────────────────────────────────────
            HStack {
                Text("Per side")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(6)
                        .background(Circle().fill(Color(white: 0.2)))
                }
                .buttonStyle(.plain)
            }

            // ── Plate changes — single row ≤ 3, 3-col grid > 3 ───────────
            if delta.count <= 3 {
                HStack(spacing: 16) {
                    ForEach(delta, id: \.weight) { item in
                        changeCell(weight: item.weight, change: item.change)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading),
                        GridItem(.flexible(), alignment: .leading)
                    ],
                    spacing: 8
                ) {
                    ForEach(delta, id: \.weight) { item in
                        changeCell(weight: item.weight, change: item.change)
                    }
                }
            }

            // ── Countdown bar (auto-dismiss only) ─────────────────────────
            if duration > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(white: 0.2))
                        Capsule()
                            .fill(ThemeTokens.accent.opacity(0.7))
                            .frame(width: geo.size.width * progress)
                            .animation(.linear(duration: duration), value: progress)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.13))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(white: 0.22), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
        .onAppear {
            guard duration > 0 else { return }
            progress = 0
            Task {
                try? await Task.sleep(for: .seconds(duration))
                onDismiss()
            }
        }
    }

    private func changeCell(weight: Double, change: Int) -> some View {
        HStack(spacing: 5) {
            Text(change > 0 ? "+" : "−")
                .font(.caption2.weight(.black))
                .foregroundStyle(change > 0 ? ThemeTokens.deltaAdd : ThemeTokens.deltaRemove)
            Circle()
                .fill(ThemeTokens.plateColor(for: weight, unit: unit))
                .frame(width: 9, height: 9)
            Text("\(abs(change))×\(weight.weightString)")
                .font(.callout.weight(.bold))
                .monospaced()
                .foregroundStyle(ThemeTokens.textPrimary)
        }
    }
}
