import SwiftUI

struct PlateInventoryView: View {
    @Binding var inventory: [PlateInventoryItem]
    let unit: WeightUnit

    var body: some View {
        List {
            ForEach($inventory) { $item in
                HStack {
                    Toggle(isOn: $item.isEnabled) {
                        Text("\(formatWeight(item.weight)) \(unit.symbol)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(item.isEnabled ? ThemeTokens.textPrimary : ThemeTokens.textMuted)
                    }
                    .tint(ThemeTokens.accent)
                }
            }
        }
        .navigationTitle("Plate Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(ThemeTokens.backgroundPrimary)
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
