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
                case .verified:
                    settings.isPro = true
                    Logger.storeKit.info("Pro unlocked via purchase")
                case .unverified(_, let error):
                    Logger.storeKit.error("Unverified purchase: \(error.localizedDescription)")
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Purchase is pending."
            @unknown default:
                break
            }
        } catch {
            Logger.storeKit.error("Purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases(settings: AppSettings) async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                settings.isPro = true
                Logger.storeKit.info("Pro restored from entitlements")
            }
        }
    }
}
