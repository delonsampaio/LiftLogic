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

                    if item.isEnabled {
                        quantityControl(item: $item)
                    }
                }
            }
        }
        .navigationTitle("Plate Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(ThemeTokens.backgroundPrimary)
    }

    @ViewBuilder
    private func quantityControl(item: Binding<PlateInventoryItem>) -> some View {
        HStack(spacing: 4) {
            Button {
                let q = item.wrappedValue.quantity
                item.wrappedValue.quantity = q == Int.max ? 4 : max(2, q - 2)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(ThemeTokens.textSecondary)
            }
            .buttonStyle(.plain)

            Text(item.wrappedValue.quantity == Int.max ? "∞" : "×\(item.wrappedValue.quantity)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(item.wrappedValue.quantity == Int.max ? ThemeTokens.textMuted : ThemeTokens.textSecondary)
                .frame(minWidth: 30, alignment: .center)

            Button {
                let q = item.wrappedValue.quantity
                guard q != Int.max else { return }
                item.wrappedValue.quantity = q >= 20 ? Int.max : q + 2
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.wrappedValue.quantity == Int.max ? ThemeTokens.textMuted : ThemeTokens.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(item.wrappedValue.quantity == Int.max)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : "\(w)"
    }
}
