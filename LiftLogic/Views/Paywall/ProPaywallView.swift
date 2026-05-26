import SwiftUI
import StoreKit

struct ProPaywallView: View {
    let settings: AppSettings
    @State private var store = StoreKitService()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            ThemeTokens.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("LiftLogic Pro")
                        .font(.largeTitle.weight(.black))
                        .foregroundStyle(ThemeTokens.accentPro)
                    Text("One-time purchase. No subscription.")
                        .font(.subheadline)
                        .foregroundStyle(ThemeTokens.textMuted)
                }
                .padding(.top, 32)

                // Feature list
                VStack(alignment: .leading, spacing: 14) {
                    proFeatureRow("WARMUP Mode", "50/60/70/80/90% warm-up table")
                    proFeatureRow("1RM Mode", "Epley + Brzycki estimators")
                    proFeatureRow("REVERSE Mode", "Tap plates to build, undo last")
                    proFeatureRow("Saved Setups", "Name and recall any barbell config")
                    proFeatureRow("Bodyweight Ratio", "See your lift as a multiple of BW")
                    proFeatureRow("Rest Timer", "Live Activity in Dynamic Island")
                }
                .padding(.horizontal, 24)

                Spacer()

                // Price button
                Button {
                    Task { await store.purchase(settings: settings) }
                } label: {
                    HStack {
                        if store.isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(store.product.map { "Unlock Pro — \($0.displayPrice)" } ?? "Unlock Pro — $1.99")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeTokens.accentPro)
                    )
                }
                .padding(.horizontal, 24)
                .disabled(store.isPurchasing)
                .onChange(of: settings.isPro) { _, isPro in
                    if isPro { dismiss() }
                }

                Button("Restore Purchases") {
                    Task { await store.restorePurchases(settings: settings) }
                }
                .font(.footnote)
                .foregroundStyle(ThemeTokens.textMuted)

                Button("Not Now") { dismiss() }
                    .font(.footnote)
                    .foregroundStyle(ThemeTokens.textMuted)
                    .padding(.bottom, 16)
            }
        }
        .task { await store.fetchProducts() }
    }

    @ViewBuilder
    private func proFeatureRow(_ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(ThemeTokens.accentPro)
                .font(.body)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeTokens.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(ThemeTokens.textMuted)
            }
        }
    }
}
