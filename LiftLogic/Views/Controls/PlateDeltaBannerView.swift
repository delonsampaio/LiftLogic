import SwiftUI

/// Floating toast showing plates to add / remove per side.
/// When `duration` > 0 the toast auto-dismisses after that many seconds and
/// shows a draining progress bar. When `duration` == 0 it stays until the
/// user taps ×. Recreate (change `.id(…)`) when the delta changes to restart.
struct PlateDeltaBannerView: View {
    let delta: [(weight: Double, change: Int)]
    let unit: WeightUnit
    /// Seconds until auto-dismiss. 0 = stay until manually dismissed (no bar shown).
    let duration: Double
    let onDismiss: () -> Void

    @State private var progress: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ── Plate changes + dismiss button ────────────────────────────
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(delta, id: \.weight) { weight, change in
                            HStack(spacing: 5) {
                                Text(change > 0 ? "+" : "−")
                                    .font(.caption2.weight(.black))
                                    .foregroundStyle(
                                        change > 0 ? ThemeTokens.deltaAdd : ThemeTokens.deltaRemove
                                    )
                                Circle()
                                    .fill(ThemeTokens.plateColor(for: weight, unit: unit))
                                    .frame(width: 9, height: 9)
                                Text("\(abs(change))×\(weight.weightString)")
                                    .font(.callout.weight(.bold))
                                    .monospaced()
                                    .foregroundStyle(ThemeTokens.textPrimary)
                            }
                        }
                        Text("per side")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ThemeTokens.textMuted)
                    }
                    .padding(.trailing, 8)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeTokens.textMuted)
                        .padding(6)
                        .background(Circle().fill(Color(white: 0.2)))
                }
                .buttonStyle(.plain)
            }

            // ── Countdown bar (only when auto-dismiss is on) ──────────────
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
}
