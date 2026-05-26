import SwiftUI

struct PlateRackView: View {
    let inventory: [PlateInventoryItem]
    let unit: WeightUnit
    let isAvailable: (PlateInventoryItem) -> Bool
    let onTap: (PlateInventoryItem) -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    private var enabledPlates: [PlateInventoryItem] {
        inventory.filter(\.isEnabled).sorted { $0.weight > $1.weight }
    }

    private var columnCount: Int { sizeClass == .regular ? 4 : 3 }
    private var plateSize: CGFloat { sizeClass == .regular ? 112 : 88 }

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible()), count: columnCount)
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(enabledPlates) { plate in
                let available = isAvailable(plate)
                Button {
                    onTap(plate)
                } label: {
                    PlateButton(weight: plate.weight, unit: unit, size: plateSize)
                        .opacity(available ? 1.0 : 0.35)
                }
                .buttonStyle(NumpadButtonStyle())
                .disabled(!available)
            }
        }
        .padding(.horizontal)
    }
}

/// Circular plate-face button — matches the real-world view of a plate on a rack.
private struct PlateButton: View {
    let weight: Double
    let unit: WeightUnit
    let size: CGFloat

    private var plateColor: Color {
        ThemeTokens.plateColor(for: weight, unit: unit)
    }

    var body: some View {
        let scale = size / 88
        ZStack {
            // Outer rim — dark rolled-steel edge
            Circle()
                .fill(plateColor.opacity(0.52))

            // Plate face — domed: full color at center, dark at rim
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            plateColor,
                            plateColor.opacity(0.80),
                            plateColor.opacity(0.48)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 44 * scale
                    )
                )
                .padding(4)

            // Weight label — upper portion, independent ZStack layer
            Text(weight.weightString)
                .font(.system(size: 18 * scale, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.65), radius: 1, x: 0, y: 1)
                .offset(y: -20 * scale)

            // Metallic hub — dead center, smaller bore for clarity
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.78), Color(white: 0.36)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 9 * scale
                    )
                )
                .frame(width: 16 * scale, height: 16 * scale)
                .overlay(Circle().strokeBorder(Color(white: 0.18), lineWidth: 0.75))

            // Top-left specular arc — matte anodized surface reflection
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear,                    location: 0.00),
                            .init(color: .clear,                    location: 0.70),
                            .init(color: .white.opacity(0.25),      location: 0.82),
                            .init(color: .white.opacity(0.18),      location: 0.92),
                            .init(color: .clear,                    location: 1.00),
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle:   .degrees(270)
                    ),
                    lineWidth: 2
                )
                .padding(4)
        }
        .frame(width: size, height: size)
    }
}
