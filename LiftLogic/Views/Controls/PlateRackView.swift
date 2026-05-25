import SwiftUI

struct PlateRackView: View {
    let inventory: [PlateInventoryItem]
    let unit: WeightUnit
    let onTap: (PlateInventoryItem) -> Void

    private var enabledPlates: [PlateInventoryItem] {
        inventory.filter(\.isEnabled).sorted { $0.weight > $1.weight }
    }

    var body: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(enabledPlates) { plate in
                Button {
                    onTap(plate)
                } label: {
                    PlateButton(weight: plate.weight, unit: unit)
                }
                .buttonStyle(NumpadButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

/// Circular plate-face button — matches the real-world view of a plate on a rack.
private struct PlateButton: View {
    let weight: Double
    let unit: WeightUnit

    private var plateColor: Color {
        ThemeTokens.plateColor(for: weight, unit: unit)
    }

    var body: some View {
        ZStack {
            // Outer ring — darkened rim of the plate
            Circle()
                .fill(plateColor.opacity(0.75))

            // Main plate face — slightly inset with radial gradient for depth
            Circle()
                .fill(
                    RadialGradient(
                        colors: [plateColor, plateColor.opacity(0.82)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 28
                    )
                )
                .padding(4)

            // Center hub — the hole/boss of a real plate
            Circle()
                .fill(Color(white: 0.08))
                .frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(Color(white: 0.25), lineWidth: 0.5))

            // Weight label — sits above hub, slightly offset upward
            Text(formatWeight(weight))
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                .offset(y: -1)

            // Top-edge highlight for elevation (consistent with numpad)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.30), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: 64, height: 64)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}

// Keep formatWeight on PlateRackView for backward compat
private extension PlateRackView {
    func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
