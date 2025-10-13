//
//  PaywallStore.swift
//  AwesomePaywall StoreKit 2 Store
//
//  Created by Arne Gockeln on 28.09.25.
//
//  Talk to the StoreKit servers and handle realtime updates of transactions.

import Foundation
import StoreKit

@MainActor
public final class PaywallStore: ObservableObject {
    enum Error: LocalizedError {
        case restorePurchase, loadProducts

        var errorDescription: String? {
            switch self {
                case .restorePurchase:
                    return "Restore Purchase"
                case .loadProducts:
                    return "Load Products"
            }
        }

        var recoverySuggestion: String? {
            switch self {
                case .restorePurchase:
                    return "An error occoured. Purchases are not restored."
                case .loadProducts:
                    return "An error occoured. Products are not loaded."
            }
        }
    }

    private(set) public var productIDs: [String] = []
    private var productsLoaded: Bool = false

    @Published public var isPaywallPresented: Bool = false
    @Published public var isLoading: Bool = false

    @Published public var products: [Product] = []
    @Published private(set) var activeSubscriptions: Set<StoreKit.Transaction> = []
    @Published public var selectedProduct: Product?

    @Published var error: Swift.Error?

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

            default:
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
            self.error = Error.restorePurchase
        }
    }

    /// Calculate discount of yearly to weekly product
    public func calculateDiscount(for product: Product) async -> Int? {
        guard product.subscription?.subscriptionPeriod.unit == .year,
              let weekly = await findProduct(by: .weekly)?.price else {
            return nil
        }

        let yearly = product.price
        let weeklyPerYear = weekly * 4 * 12
        let discount = (100.0 - (yearly / weeklyPerYear * 100.0)).rounded(1, .bankers).toInt()

        return discount
    }

    /// Get product by subscription period
    public func findProduct(by period: Product.SubscriptionPeriod) async -> Product? {
        return products.filter({ $0.subscription?.subscriptionPeriod == period }).first
    }

    /// Select a product by SubscriptionPeriod
    public func select(by period: Product.SubscriptionPeriod) async {
        guard let product = await findProduct(by: period) else { return }
        self.selectedProduct = product
    }

    /// Check if given product is selected
    public func isSelected(_ product: Product) -> Bool {
        guard let selectedProduct else { return false }
        return product.id == selectedProduct.id
    }

    // Check if self.selectedProduct equals period
    // Used in purchaseButton
    public func isSelected(period: Product.SubscriptionPeriod) -> Bool {
        guard let product = self.selectedProduct,
              product.subscription?.subscriptionPeriod == period else {
            return false
        }
        return true
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
            self.error = Error.loadProducts
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
