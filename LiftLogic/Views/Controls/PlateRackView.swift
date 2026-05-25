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
            // Outer ring — darkened plate rim
            Circle()
                .fill(plateColor.opacity(0.70))

            // Main plate face — radial gradient for subtle depth
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

            // Weight label — upper half of plate, clear of the bore
            Text(formatWeight(weight))
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.55), radius: 1, x: 0, y: 1)
                .offset(y: -12)

            // Center bore — WHITE, like competition/IWF plates
            Circle()
                .fill(Color(white: 0.88))
                .frame(width: 16, height: 16)
                .overlay(Circle().strokeBorder(Color(white: 0.55), lineWidth: 0.5))

            // Top-edge elevation highlight (consistent with numpad keys)
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
