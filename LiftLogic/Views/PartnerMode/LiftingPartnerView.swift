import SwiftUI

struct LiftingPartnerView: View {
    let vm: CalculatorViewModel
    let settings: AppSettings
    let onSetupLoaded: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                NavigationLink {
                    ShowMyQRView(vm: vm, settings: settings)
                } label: {
                    partnerActionRow(icon: "qrcode", title: "Show My QR Code", subtitle: "Let your partner scan your current setup")
                }
                NavigationLink {
                    ScanPartnerView(vm: vm, settings: settings, onSetupLoaded: onSetupLoaded)
                } label: {
                    partnerActionRow(icon: "camera.viewfinder", title: "Scan Partner's Code", subtitle: "Load your partner's setup")
                }
                Spacer()
            }
            .padding()
            .background(ThemeTokens.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Lifting Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private func partnerActionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(settings.accentColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ThemeTokens.textMuted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(ThemeTokens.textMuted)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeTokens.backgroundCard))
    }
}
