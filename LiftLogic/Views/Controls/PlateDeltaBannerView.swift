import SwiftUI

/// Shows what plates to add or remove per side compared to the last committed weight.
/// Positive change = add (green), negative change = remove (amber).
struct PlateDeltaBannerView: View {
    /// Each element is (plateWeight, netChangePerSide). Sorted heaviest-first by the VM.
    let delta: [(weight: Double, change: Int)]
    let unit: WeightUnit

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(delta, id: \.weight) { weight, change in
                    HStack(spacing: 5) {
                        // +/− badge
                        Text(change > 0 ? "+" : "−")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(change > 0 ? ThemeTokens.deltaAdd : ThemeTokens.deltaRemove)

                        // Plate colour dot
                        Circle()
                            .fill(ThemeTokens.plateColor(for: weight, unit: unit))
                            .frame(width: 9, height: 9)

                        // Count × weight
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
            .padding(.horizontal, 16)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .frame(maxWidth: .infinity)
    }
}
