import SwiftUI

struct PartnerScanConfirmationView: View {
    let payload: PartnerSetupPayload
    let accentColor: Color
    let onLoad: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Load this setup?")
                    .font(.headline)
                    .foregroundStyle(ThemeTokens.textPrimary)
                Text("\(payload.weight.weightString) \(payload.unit.symbol) · \(payload.barType.displayName)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
                if payload.barType == .custom, let customBarWeight = payload.customBarWeight {
                    Text("Custom bar: \(customBarWeight.weightString) \(payload.unit.symbol)")
                        .font(.subheadline)
                        .foregroundStyle(ThemeTokens.textMuted)
                }
                Spacer()
            }
            .padding(.top, 32)
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Partner Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Load") { onLoad() }
                        .foregroundStyle(accentColor)
                }
            }
        }
    }
}
