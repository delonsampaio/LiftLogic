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
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(enabledPlates) { plate in
                Button {
                    onTap(plate)
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ThemeTokens.plateColor(for: plate.weight, unit: unit))
                            .frame(height: 52)
                        Text(formatWeight(plate.weight))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                    }
                }
                .buttonStyle(NumpadButtonStyle())
            }
        }
        .padding(.horizontal)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
