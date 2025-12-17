import Foundation
import StoreKit
internal import Combine

/// Handles in-app purchases using StoreKit 2
@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    // MARK: - Product IDs
    // "let" properties are thread-safe by default
    private let productIDs: Set<String> = [
        "praxisen_premium_monthly",
        "praxisen_premium_yearly"
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

    // MARK: - Helper Methods
    
    /// Checks if the product ID belongs to a premium subscription
    /// marked 'nonisolated' so it can be called from background tasks
    nonisolated private func isPremiumProduct(_ productID: String) -> Bool {
        return productIDs.contains(productID)
    }

    // MARK: - Product Management

    /// Loads available products from the App Store
    func loadProducts() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            
            // Sort products by price (optional, but good for UI consistency)
            products.sort { $0.price < $1.price }
            
        } catch {
            print("❌ Failed to load products: \(error)")
            throw PurchaseError.productLoadFailed
        }
    }

    /// Returns the monthly premium product if available
    var monthlyPremiumProduct: Product? {
        return products.first { $0.id == "praxisen_premium_monthly" }
    }

    /// Returns the yearly premium product if available
    var yearlyPremiumProduct: Product? {
        return products.first { $0.id == "praxisen_premium_yearly" }
    }

    // MARK: - Purchase Methods

    /// Purchases the premium subscription (monthly or yearly)
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

                await handleSubscriptionTransaction(transaction)
                await transaction.finish()
                
                purchaseState = .purchased
                return transaction

            case .pending:
                purchaseState = .pending
                throw PurchaseError.purchasePending

            case .userCancelled:
                purchaseState = .cancelled
                throw PurchaseError.purchaseCancelled

            @unknown default:
                purchaseState = .failed
                throw PurchaseError.unknownError
            }

        } catch {
            purchaseState = .failed
            throw error is PurchaseError ? error : PurchaseError.purchaseFailed
        }
    }

    /// Restores previous purchases
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            purchaseState = .restoring
            
            // We only need to find ONE valid active subscription to unlock the app
            var foundActiveSubscription = false

            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                // Check if this is a valid premium subscription
                if isPremiumProduct(transaction.productID) && transaction.revocationDate == nil {
                    
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        // Found valid active subscription
                        await SubscriptionManager.shared.activatePremiumSubscription(
                            startDate: transaction.purchaseDate,
                            expirationDate: expirationDate
                        )
                        foundActiveSubscription = true
                        purchaseState = .restored
                        // Once found, we can stop checking
                        return
                    }
                }
            }

            // If loop finishes and nothing was found
            if !foundActiveSubscription {
                await SubscriptionManager.shared.deactivatePremiumSubscription()
                purchaseState = .idle // Or keep it as is, implying no restore happened
            }

        } catch {
            purchaseState = .failed
            throw error is PurchaseError ? error : PurchaseError.restoreFailed
        }
    }

    /// Checks current subscription status quietly (on app launch)
    func checkSubscriptionStatus() async {
        do {
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                if isPremiumProduct(transaction.productID) && transaction.revocationDate == nil {
                    if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                        
                        // Active subscription found. Use the actual purchase date from Apple.
                        await SubscriptionManager.shared.activatePremiumSubscription(
                            startDate: transaction.purchaseDate,
                            expirationDate: expirationDate
                        )
                        return // Exit as soon as we verify access
                    }
                }
            }

            // If we exit the loop, no active subscription was found
            await SubscriptionManager.shared.deactivatePremiumSubscription()

        } catch {
            // Silently fail on check status, just ensure local state is safe
            await SubscriptionManager.shared.refreshSubscriptionStatus()
        }
    }

    /// Get subscription renewal information
    func getSubscriptionInfo() async -> SubscriptionStatus? {
        do {
            // Iterate entitlements to find the active one
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                if isPremiumProduct(transaction.productID) && transaction.revocationDate == nil {
                    // Check if it's strictly active
                    let isActive = (transaction.expirationDate ?? Date.distantFuture) > Date()
                    
                    return SubscriptionStatus(
                        isActive: isActive,
                        expirationDate: transaction.expirationDate,
                        purchaseDate: transaction.purchaseDate,
                        originalTransactionId: String(transaction.originalID)
                    )
                }
            }
            return nil
        } catch {
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

    /// Listens for transaction updates (e.g. renewals happening in background)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // Because this task is detached, we need 'nonisolated' access to helpers
                    let transaction = try self.checkVerified(result)

                    if self.isPremiumProduct(transaction.productID) {
                        await self.handleSubscriptionTransaction(transaction)
                    }

                    await transaction.finish()

                } catch {
                    print("❌ Transaction verification failed in listener: \(error)")
                }
            }
        }
    }

    /// Handles subscription-related transactions
    private func handleSubscriptionTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            // Check expiry
            if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                await SubscriptionManager.shared.activatePremiumSubscription(
                    startDate: transaction.purchaseDate,
                    expirationDate: expirationDate
                )
            } else {
                await SubscriptionManager.shared.deactivatePremiumSubscription()
            }
        } else {
            // Subscription was revoked (refunded, etc.)
            await SubscriptionManager.shared.deactivatePremiumSubscription()
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
