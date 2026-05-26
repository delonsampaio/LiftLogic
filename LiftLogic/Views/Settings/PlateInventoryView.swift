import SwiftUI

struct PlateInventoryView: View {
    @Binding var inventory: [PlateInventoryItem]
    let unit: WeightUnit
    let isPro: Bool

    @State private var showResetConfirm = false

    private var defaults: [PlateInventoryItem] {
        unit == .lbs ? AppSettings.defaultLbs : AppSettings.defaultKg
    }

    var body: some View {
        List {
            ForEach($inventory) { $item in
                HStack {
                    Toggle(isOn: $item.isEnabled) {
                        Text("\(item.weight.weightString) \(unit.symbol)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(item.isEnabled ? ThemeTokens.textPrimary : ThemeTokens.textMuted)
                    }
                    .tint(ThemeTokens.accent)

                    if item.isEnabled {
                        if isPro {
                            quantityControl(item: $item)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(ThemeTokens.textMuted)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plate Inventory")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(ThemeTokens.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") { showResetConfirm = true }
                    .foregroundStyle(ThemeTokens.textSecondary)
            }
        }
        .confirmationDialog("Restore defaults?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Restore Defaults", role: .destructive) { inventory = defaults }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All plate toggles and quantity limits will be reset.")
        }
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
                if q == Int.max {
                    item.wrappedValue.quantity = 4
                } else if q >= 20 {
                    item.wrappedValue.quantity = Int.max
                } else {
                    item.wrappedValue.quantity = q + 2
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(ThemeTokens.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

}
