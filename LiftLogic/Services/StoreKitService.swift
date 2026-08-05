import StoreKit
import Observation
import OSLog

@Observable
@MainActor
final class StoreKitService {
    static let proProductID = "com.DelonSampaio.LiftLogic.pro"

    var product: Product?
    var isPurchasing = false
    var errorMessage: String?
    /// Set after a restore attempt so the UI can confirm the outcome to the user.
    var restoreMessage: String?

    private var updatesTask: Task<Void, Never>?

    /// Call once at launch. Reconciles Pro state with the App Store and starts
    /// listening for transactions that arrive outside a direct purchase — Family
    /// Sharing, Ask-to-Buy approvals, purchases made on another device, and refunds.
    func start(settings: AppSettings) {
        Task { await refreshEntitlements(settings: settings) }
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.apply(update, settings: settings)
            }
        }
    }

    /// Sets `isPro` to the true current-entitlement state. Unlocks when the Pro
    /// product is owned and not revoked; re-locks after a refund/revocation.
    /// `currentEntitlements` is served from the on-device cache, so this is safe offline.
    func refreshEntitlements(settings: AppSettings) async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        settings.isPro = owned
    }

    func fetchProducts() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            product = products.first
        } catch {
            Logger.storeKit.error("Failed to fetch products: \(error.localizedDescription)")
            errorMessage = "Could not load product."
        }
    }

    func purchase(settings: AppSettings) async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    settings.isPro = true
                    // Non-consumables must be finished or StoreKit re-delivers them forever.
                    await transaction.finish()
                    Logger.storeKit.info("Pro unlocked via purchase")
                case .unverified(_, let error):
                    Logger.storeKit.error("Unverified purchase: \(error.localizedDescription)")
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch {
            Logger.storeKit.error("Purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases(settings: AppSettings) async {
        var restored = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID,
               transaction.revocationDate == nil {
                settings.isPro = true
                restored = true
                Logger.storeKit.info("Pro restored from entitlements")
            }
        }
        restoreMessage = restored ? "Pro restored." : "No previous purchase found to restore."
    }

    /// Handles a transaction delivered via `Transaction.updates` and finishes it.
    private func apply(_ result: VerificationResult<Transaction>, settings: AppSettings) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.proProductID {
            settings.isPro = (transaction.revocationDate == nil)
        }
        await transaction.finish()
    }
}
