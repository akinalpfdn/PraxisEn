import Foundation
import StoreKit
internal import Combine
/// Handles in-app purchases using StoreKit 2
@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Product IDs
    private let productIDs: Set<String> = [
        "praxisen_premium_monthly"
        // Add "praxisen_premium_yearly" when ready
    ]

    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var purchaseState: PurchaseState = .idle

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Initialization
    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Management

    /// Loads available products from the App Store
    func loadProducts() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
            throw PurchaseError.productLoadFailed
        }
    }

    /// Returns the monthly premium product if available
    var monthlyPremiumProduct: Product? {
        return products.first { $0.id == "praxisen_premium_monthly" }
    }

    // MARK: - Purchase Methods

    /// Purchases the premium subscription
    func purchasePremium(_ product: Product) async throws -> Transaction {
        guard product.type == .autoRenewable else {
            throw PurchaseError.invalidProduct
        }

        isLoading = true
        defer { isLoading = false }

        do {
            purchaseState = .purchasing

            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                // Update subscription manager with successful purchase
                await SubscriptionManager.shared.activatePremiumSubscription(
                    startDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate
                )

                await transaction.finish() // Consume the transaction
                purchaseState = .purchased
                print("✅ Premium purchase successful")

                return transaction

            case .pending:
                purchaseState = .pending
                print("📱 Purchase pending, requires approval")
                throw PurchaseError.purchasePending

            case .userCancelled:
                purchaseState = .cancelled
                print("❌ Purchase cancelled by user")
                throw PurchaseError.purchaseCancelled

            @unknown default:
                purchaseState = .failed
                throw PurchaseError.unknownError
            }

        } catch {
            purchaseState = .failed
            print("❌ Purchase failed: \(error)")
            throw error is PurchaseError ? error : PurchaseError.purchaseFailed
        }
    }

    /// Restores previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            purchaseState = .restoring

            var hasActiveSubscription = false
            var subscriptionExpiration: Date?

            for await result in Transaction.currentEntitlements {
                let verifiedTransaction = try checkVerified(result)

                // Check for premium subscription
                if verifiedTransaction.productID == "praxisen_premium_monthly" {
                    if verifiedTransaction.revocationDate == nil {
                        // Subscription is not revoked
                        if verifiedTransaction.expirationDate ?? Date.distantFuture > Date() {
                            // Subscription is active
                            hasActiveSubscription = true
                            subscriptionExpiration = verifiedTransaction.expirationDate
                        }
                    }
                }
            }

            // Update subscription manager based on restored status
            if hasActiveSubscription {
                let startDate = subscriptionExpiration?.addingTimeInterval(-30 * 24 * 60 * 60) ?? Date()
                await SubscriptionManager.shared.activatePremiumSubscription(
                    startDate: startDate,
                    expirationDate: subscriptionExpiration
                )
                purchaseState = .restored
                print("✅ Premium subscription restored")
            } else {
                await SubscriptionManager.shared.deactivatePremiumSubscription()
                purchaseState = .idle
                print("ℹ️ No active subscription found")
            }

        } catch {
            purchaseState = .failed
            print("❌ Restore failed: \(error)")
            throw error is PurchaseError ? error : PurchaseError.restoreFailed
        }
    }

    /// Checks current subscription status
    func checkSubscriptionStatus() async {
        do {
            var hasActiveSubscription = false
            var subscriptionExpiration: Date?

            for await result in Transaction.currentEntitlements {
                let verifiedTransaction = try checkVerified(result)

                if verifiedTransaction.productID == "praxisen_premium_monthly" {
                    if verifiedTransaction.revocationDate == nil {
                        if verifiedTransaction.expirationDate ?? Date.distantFuture > Date() {
                            hasActiveSubscription = true
                            subscriptionExpiration = verifiedTransaction.expirationDate
                        }
                    }
                }
            }

            if hasActiveSubscription {
                let startDate = subscriptionExpiration?.addingTimeInterval(-30 * 24 * 60 * 60) ?? Date()
                await SubscriptionManager.shared.activatePremiumSubscription(
                    startDate: startDate,
                    expirationDate: subscriptionExpiration
                )
                print("✅ Active subscription verified")
            } else {
                SubscriptionManager.shared.refreshSubscriptionStatus()
                print("ℹ️ No active subscription")
            }

        } catch {
            print("❌ Subscription status check failed: \(error)")
            SubscriptionManager.shared.refreshSubscriptionStatus()
        }
    }

    /// Get subscription renewal information
    func getSubscriptionInfo() async -> SubscriptionStatus? {
        do {
            for await result in Transaction.currentEntitlements {
                let verifiedTransaction = try checkVerified(result)

                if verifiedTransaction.productID == "praxisen_premium_monthly" {
                    if verifiedTransaction.revocationDate == nil {
                        let isActive = verifiedTransaction.expirationDate ?? Date.distantFuture > Date()
                        return SubscriptionStatus(
                            isActive: isActive,
                            expirationDate: verifiedTransaction.expirationDate,
                            purchaseDate: verifiedTransaction.purchaseDate,
                            originalTransactionId: String(verifiedTransaction.originalID)
                        )
                    }
                }
            }
            return nil
        } catch {
            print("❌ Failed to get subscription info: \(error)")
            return nil
        }
    }

    // MARK: - Transaction Verification

    /// Verifies a transaction result
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    /// Listens for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Handle the transaction
                    if transaction.productID == "praxisen_premium_monthly" {
                        await self.handleSubscriptionTransaction(transaction)
                    }

                    await transaction.finish()

                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Handles subscription-related transactions
    private func handleSubscriptionTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            // Subscription is active
            let isActive = transaction.expirationDate ?? Date.distantFuture > Date()

            if isActive {
                SubscriptionManager.shared.activatePremiumSubscription(
                    startDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate
                )
                print("✅ Subscription activated/updated")
            } else {
                SubscriptionManager.shared.deactivatePremiumSubscription()
                print("ℹ️ Subscription expired")
            }
        } else {
            // Subscription was revoked
            SubscriptionManager.shared.deactivatePremiumSubscription()
            print("ℹ️ Subscription revoked")
        }
    }
}

// MARK: - Supporting Types

enum PurchaseState {
    case idle
    case loading
    case purchasing
    case purchased
    case pending
    case cancelled
    case restoring
    case restored
    case failed
}

enum PurchaseError: LocalizedError {
    case productLoadFailed
    case purchaseFailed
    case purchasePending
    case purchaseCancelled
    case restoreFailed
    case verificationFailed
    case invalidProduct
    case unknownError

    var errorDescription: String? {
        switch self {
        case .productLoadFailed:
            return "Failed to load products from the App Store."
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .purchasePending:
            return "Purchase is pending approval. Please check your account settings."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .restoreFailed:
            return "Failed to restore purchases. Please try again."
        case .verificationFailed:
            return "Transaction verification failed. Please contact support."
        case .invalidProduct:
            return "Invalid product selected."
        case .unknownError:
            return "An unknown error occurred."
        }
    }
}

struct SubscriptionStatus {
    let isActive: Bool
    let expirationDate: Date?
    let purchaseDate: Date
    let originalTransactionId: String

    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
    }

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
}
