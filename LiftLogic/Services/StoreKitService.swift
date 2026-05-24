import StoreKit
import Observation

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
                case .unverified:
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
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases(settings: AppSettings) async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proProductID {
                settings.isPro = true
            }
        }
    }
}
