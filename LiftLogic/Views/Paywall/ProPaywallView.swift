import SwiftUI
import StoreKit

struct ProPaywallView: View {
    let settings: AppSettings
    let store: StoreKitService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            ThemeTokens.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
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
                            proFeatureRow("WARMUP Mode", "Customizable warm-up ladder")
                            proFeatureRow("1RM Mode", "Epley, Brzycki + RPE-based estimate")
                            proFeatureRow("Relative Strength", "Wilks, DOTS & IPF GL Points scoring")
                            proFeatureRow("REVERSE Mode", "Tap plates to build, undo last")
                            proFeatureRow("Saved Setups", "Name and recall any barbell config")
                            proFeatureRow("Barbell History", "Auto-saves your last 10 configs")
                            proFeatureRow("Bodyweight Ratio", "See your lift as a multiple of BW")
                            proFeatureRow("Rest Timer", "Live Activity in Dynamic Island")
                            proFeatureRow("Plate Quantity Limits", "Never suggests plates you don't own")
                            proFeatureRow("Lifting Partner", "Share a setup via QR code")
                            proFeatureRow("Decimal Precision Lock", "Always loadable targets")
                            proFeatureRow("Accent Color", "Personalize the app's accent")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 16)
                }

                // Pinned footer — always on-screen regardless of device size or
                // how long the feature list above grows; only the list scrolls.
                VStack(spacing: 12) {
                    Button {
                        Task { await store.purchase(settings: settings) }
                    } label: {
                        HStack {
                            if store.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(store.product.map { "Unlock Pro — \($0.displayPrice)" } ?? "Unlock Pro — $0.99")
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
                    .disabled(store.isPurchasing)
                    .onChange(of: settings.isPro) { _, isPro in
                        if isPro { dismiss() }
                    }

                    Button("Restore Purchases") {
                        Task { await store.restorePurchases(settings: settings) }
                    }
                    .font(.footnote)
                    .foregroundStyle(ThemeTokens.textMuted)

                    if let message = store.restoreMessage ?? store.errorMessage {
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(ThemeTokens.textMuted)
                            .multilineTextAlignment(.center)
                    }

                    Button("Not Now") { dismiss() }
                        .font(.footnote)
                        .foregroundStyle(ThemeTokens.textMuted)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
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
