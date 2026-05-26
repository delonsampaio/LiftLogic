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
        LazyVGrid(columns: columns, spacing: 16) {
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
                        endRadius: 44
                    )
                )
                .padding(4)

            // Weight label — upper portion, independent ZStack layer
            Text(weight.weightString)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.65), radius: 1, x: 0, y: 1)
                .offset(y: -20)

            // Metallic hub — dead center, smaller bore for clarity
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.78), Color(white: 0.36)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 9
                    )
                )
                .frame(width: 16, height: 16)
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
        .frame(width: 88, height: 88)
    }
}
