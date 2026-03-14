//
//  StoreKitManager.swift
//  Kaizen OS
//

import StoreKit

@Observable
final class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var product: Product?
    private(set) var isPurchased = false
    private(set) var isLoading = false

    private let productID = "com.shubh.kaizenos.premium"
    private var updateListenerTask: Task<Void, Never>?

    init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProduct() }
        Task { await checkPurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    @MainActor
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    @MainActor
    func purchase() async throws {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            isPurchased = true
            await transaction.finish()
        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == productID {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    // nonisolated: called from Task.detached in listenForTransactions — no actor required
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await MainActor.run {
                        self.isPurchased = true
                    }
                    await transaction.finish()
                }
            }
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
