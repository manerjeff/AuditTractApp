//
//  StoreKitManager.swift
//  AuditTractApp
//
//  Created by Jeff Maner on 10/28/26.
//

import Foundation
import StoreKit
import Combine

@MainActor
final class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Product IDs
    static let annualSubscriptionID = "com.audittract.subscription.annual"
    static let monthlySubscriptionID = "com.audittract.subscription.monthly"
    static let lifetimePurchaseID = "com.audittract.purchase.lifetime"
    
    private let productIDs: Set<String> = [
        annualSubscriptionID,
        monthlySubscriptionID,
        lifetimePurchaseID
    ]
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed: Bool = false
    @Published var purchaseInProgress: Bool = false
    @Published var errorMessage: String? = nil
    
    private var transactionListener: Task<Void, Error>? = nil
    
    private init() {
        transactionListener = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Retrieval
    func requestProducts() async {
        do {
            let loadedProducts = try await Product.products(for: productIDs)
            self.products = loadedProducts.sorted { $0.price < $1.price }
        } catch {
            print("⚠️ [StoreKitManager] Failed product fetch: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Transaction Verification & Entitlements
    func updateCustomerProductStatus() async {
        var hasActiveEntitlement = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                if productIDs.contains(transaction.productID) {
                    hasActiveEntitlement = true
                    break
                }
            } catch {
                print("⚠️ [StoreKitManager] Transaction verification failed: \(error.localizedDescription)")
            }
        }
        
        self.isSubscribed = hasActiveEntitlement
    }
    
    // MARK: - Purchase Flow
    func purchase(_ product: Product) async -> Bool {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
#if os(visionOS)
            guard let windowScene = await MainActor.run(body: {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first
            }) else {
                self.errorMessage = "Unable to locate active scene for purchase."
                return false
            }
            let result = try await product.purchase(confirmIn: windowScene)
#else
            let result = try await product.purchase()
#endif
            
            switch result {
            case .success(let verification):
                let transaction = try Self.checkVerified(verification)
                await transaction.finish()
                await updateCustomerProductStatus()
                return isSubscribed
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async {
        purchaseInProgress = true
        defer { purchaseInProgress = false }
        
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Background Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("⚠️ [StoreKitManager] Unverified update: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Non-isolated verification helper
    nonisolated static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

