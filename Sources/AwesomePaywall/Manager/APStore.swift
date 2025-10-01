//
//  APStore.swift
//  AwesomePaywall StoreKit 2 Store
//
//  Created by Arne Gockeln on 28.09.25.
//
//  Talk to the StoreKit servers and handle realtime updates of transactions.

import Foundation
import StoreKit
import OSLog

private let logger = Logger(subsystem: "PushUpBattle", category: "AwesomePaywall")

@MainActor
public final class APStore: ObservableObject {
    private(set) public var productIDs: [String] = []
    private var productsLoaded: Bool = false

    @Published public var isPaywallPresented: Bool = false
    @Published public var isLoading: Bool = false
    
    public var hasProSubscription: Bool {
        return !self.purchasedProductIDs.isEmpty
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var activeSubscriptions: Set<StoreKit.Transaction> = []
    @Published private(set) var purchasedProductIDs: Set<String> = []

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

        logger.debug("APStore: configured.")
    }

    // Purchase product and activate subscription state
    public func purchase(_ product: Product) async throws {
        self.isLoading = true
        let result = try await product.purchase()
        switch result {
            case .success(let verificationResult):
                let transaction = try verificationResult.payloadValue // Throws if unverified
                activeSubscriptions.insert(transaction)
                purchasedProductIDs.insert(product.id)
                logger.debug("APStore: product \(product.displayName, privacy: .public) purchased for \(product.displayPrice, privacy: .public).")
                await transaction.finish() // avoid reprocessing
            case .userCancelled:
                logger.debug("APStore: Purchase cancelled by user")
            case .pending:
                logger.debug("APStore: Purchase pending (e.g., parental approval)")
            @unknown default:
                logger.debug("APStore: Unknown purchase result")
        }
        self.isLoading = false
    }

    /// Restore Purchases and validate entitlements
    public func restorePurchases() async {
        self.isLoading = true
        do {
            try await AppStore.sync()
            await updateActiveSubscriptions()
            if self.hasProSubscription {
                logger.debug("APStore: Purchases restored.")
            }
        } catch {
            logger.error("APStore: Restore Purchase error: \(error.localizedDescription)")
        }
        self.isLoading = false
    }

    // Load products from store API
    private func loadProducts() async {
        guard !self.productsLoaded else { return }

        self.isLoading = true
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted { $0.price > $1.price }

            logger.debug("APStore: Products loaded: \(self.products.count, privacy: .public)")
        } catch {
            logger.error("APStore: Failed to load products: \(error)")
            products = []
        }
        self.isLoading = false
    }

    // Validate active subscriptions
    private func updateActiveSubscriptions() async {
        self.isLoading = true
        var newActiveSubscriptions: Set<StoreKit.Transaction> = []
        var newPurchasedIDs: Set<String> = []

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                logger.debug("APStore: Entitlement transaction \(entitlement.debugDescription, privacy: .public) not verified!")
                continue
            }

            let state = await transaction.subscriptionStatus?.state

            switch state {
                case .subscribed:
                    newActiveSubscriptions.insert(transaction)
                    newPurchasedIDs.insert(transaction.productID)

                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): subscribed")
                case .expired:
                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): expired")
                case .inBillingRetryPeriod:
                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): inBillingRetryPeriod")
                case .inGracePeriod:
                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): inGracePeriod")
                case .revoked:
                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): revoked")
                default:
                    logger.debug("APStore: Entitlement \(transaction.productID, privacy: .public): unknown state")
            }
        }

        activeSubscriptions = newActiveSubscriptions
        purchasedProductIDs = newPurchasedIDs

        self.isLoading = false
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
