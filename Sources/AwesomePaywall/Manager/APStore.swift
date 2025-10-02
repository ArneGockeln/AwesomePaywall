//
//  APStore.swift
//  AwesomePaywall StoreKit 2 Store
//
//  Created by Arne Gockeln on 28.09.25.
//
//  Talk to the StoreKit servers and handle realtime updates of transactions.

import Foundation
import StoreKit

@MainActor
public final class APStore: ObservableObject {
    private(set) public var productIDs: [String] = []
    private var productsLoaded: Bool = false

    @Published public var isPaywallPresented: Bool = false
    @Published public var isLoading: Bool = false

    @Published var products: [Product] = []
    @Published private(set) var activeSubscriptions: Set<StoreKit.Transaction> = []
    @Published private(set) var errors: [String] = []

    // Check if a pro subscription is active
    public var hasProSubscription: Bool {
        return !self.activeSubscriptions.isEmpty
    }

    private var updateTask: Task<Void, Never>?

    public init() {
        updateTask = observeTransactionUpdates()
    }

    deinit {
        updateTask?.cancel()
    }

    // Configure the store, load products and subscribe to transactions
    public func configure(productIDs: [String]) async {
        self.productIDs = productIDs

        await loadProducts()
        await updateActiveSubscriptions()
    }

    // Purchase product and activate subscription state
    public func purchase(_ product: Product) async throws {
        self.isLoading = true
        defer { self.isLoading = false }

        let result = try await product.purchase()
        switch result {
            case .success(let verificationResult):
                let transaction = try verificationResult.payloadValue // Throws if unverified
                activeSubscriptions.insert(transaction)
                await transaction.finish() // avoid reprocessing

            @unknown default:
                return
        }
    }

    /// Restore Purchases and validate entitlements
    public func restorePurchases() async {
        self.isLoading = true
        defer { self.isLoading = false }

        do {
            try await AppStore.sync()
            await updateActiveSubscriptions()
        } catch {
            errors.append("APStore: Restore Purchase error: \(error.localizedDescription)")
        }
    }

    // Load products from store API
    private func loadProducts() async {
        guard !self.productsLoaded else { return }

        self.isLoading = true
        defer { self.isLoading = false }

        do {
            self.products = try await Product.products(for: productIDs)
                .sorted { $0.price > $1.price }
        } catch {
            errors.append("APStore: Failed to load products: \(error)")
            products = []
        }
    }

    // Validate active subscriptions
    private func updateActiveSubscriptions() async {
        var newActiveSubscriptions: Set<StoreKit.Transaction> = []

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            let state = await transaction.subscriptionStatus?.state

            switch state {
                case .subscribed:
                    newActiveSubscriptions.insert(transaction)

                default:
                    continue
            }
        }

        activeSubscriptions = newActiveSubscriptions
    }

    // Observe realtime communication
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await update in Transaction.updates {
                guard case .verified(_) = update else {
                    continue
                }

                await self.updateActiveSubscriptions()
            }
        }
    }
}
