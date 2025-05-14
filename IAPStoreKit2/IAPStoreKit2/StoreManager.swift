//
//  StoreManager.swift
//  IAPStoreKit2
//
//  Created by José Briones on 13/5/25.
//

import StoreKit

class StoreManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    
    private var productIDs = ["com.joseB91.product1", "com.yourapp.product2"]
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Handle successful transaction
                    await self.updatePurchasedProducts()
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    // Handle errors
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let storeProducts = try await StoreKit.Product.products(for: productIDs)
            self.products = storeProducts.map { storeProduct in
                Product(
                    id: storeProduct.id,
                    displayName: storeProduct.displayName,
                    description: storeProduct.description,
                    price: storeProduct.price,
                    storeKitProduct: storeProduct
                )
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.storeKitProduct.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try await checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
        
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedProducts = Set<String>()
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                if transaction.revocationDate == nil {
                    purchasedProducts.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
    }
    
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
        
    func validateReceipt(for productID: String) async throws -> Bool {
        // Local validation (basic)
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                if transaction.productID == productID && transaction.revocationDate == nil {
                    // Product is still valid
                    return true
                }
            } catch {
                throw error
            }
        }
    
        // For more security, implement server-side validation
        // by sending the App Store receipt to your server
        return false
    }
}

enum StoreError: Error {
    case failedVerification
}

