//
//  StoreManager.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 11.09.25.
//

import StoreKit
import OSLog

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()
    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var subscriptionStatus: [Product.SubscriptionInfo.Status] = []
    @Published var hasPurchased: Bool = false

    @Published var errorMessages: [String] = []

    private var updateTask: Task<Void, Never>? = nil

    private init() {
        updateTask = listenForTransactionUpdates()
    }

    deinit {
        updateTask?.cancel()
    }

    /// Fetch products from the app store and load current entitlements
    /// This should only run once. If needed set force to true and it will run again.
    func configure(force: Bool = false) async {
        if force || self.products.isEmpty {
            self.errorMessages = []
            await fetchProducts()
            await loadCurrentEntitlements()
        }
    }

    // MARK: - Caluclate Discount based on weekly and yearly price
    func calculateDiscount() -> Int {
        guard let weekly = self.products.first(where: { $0.subscription?.subscriptionPeriod == .weekly })?.price,
              let yearly = self.products.first(where: { $0.subscription?.subscriptionPeriod == .yearly })?.price else {
            return 0
        }

        let weeklyPerYear = weekly * 4 * 12
        let discount = (100.0 - (yearly / weeklyPerYear * 100.0)).rounded(1, .bankers).toInt()

        return discount
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()

            switch result {
            case let .success(.verified(transaction)):
                /// Success! Verified transaction.
                await self.handleTransaction(transaction)
                Logger.app.debug("StoreManager: Transaction was successful.")
            case let .success(.unverified(_, error)):
                /// Success but unverified transaction
                Logger.app.debug("StoreManager: Transaction was successful but unverified: \(error)")
            case .pending:
                /// Pending order
                Logger.app.debug("StoreManager: Transaction is pending.")
            case .userCancelled:
                /// User cancelled through purchase process
                Logger.app.debug("StoreManager: Transaction was cancelled.")
            @unknown default:
                /// Something different happened
                Logger.app.debug("StoreManager: Unknown purchase result.")
            }
        } catch {
            self.disableProLicense()
            Logger.app.error("StoreManager: Purchase failed: \(error, privacy: .public)")
        }
    }

    /// Restore Purchases and validate entitlements
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await loadCurrentEntitlements()
        } catch {
            Logger.app.error("StoreManager: Restore Purchase error: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Fetch Products
    private func fetchProducts() async {
        do {
            // Specify your product identifiers
            let productIds: [String] = ProductIdentifier.allCases.map { $0.rawValue }

            // Fetch products from the App Store
            products = try await Product.products(for: productIds)

            // Sort by price
            products.sort(by: { $0.price > $1.price })
        } catch {
            self.disableProLicense()
            self.errorMessages.append("StoreManager: Failed to fetch products: \(error)")
            Logger.app.error("StoreManager: Failed to fetch products: \(error, privacy: .public)")
        }
    }

    // MARK: - Load current Entitlements (Previous purchases)
    private func loadCurrentEntitlements() async {
        do {
            // Get current entitlements (action transactions for non-consumables and auto-renewable subscriptions)
            for await result in Transaction.currentEntitlements {
                let transaction = try self.checkVerified(result)
                await handleTransaction(transaction)
            }
        } catch {
            Logger.app.error("StoreManager: Failed to load current entitlements: \(error, privacy: .public)")
        }
    }

    // MARK: - Transaction Updates
    private func listenForTransactionUpdates() -> Task<Void, Never> {
        return Task.detached {
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(verificationResult)

                    await self.handleTransaction(transaction)

                    // Mark transaction as finished
                    await transaction.finish()
                } catch {
                    Logger.app.error("StoreManager: Failed to verify transaction: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }

    // MARK: - Verification Helper
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safeData):
            return safeData
        }
    }

    // MARK: - Handle Transaction
    private func handleTransaction(_ transaction: Transaction) async {
        switch transaction.productType {
        case .nonConsumable:
            // Unlock content for non-consumable product
            await unlockNonConsumable(for: transaction)
        case .autoRenewable:
            // Handle auto-renewable subscription
            await handleSubscription(for: transaction)
        default:
            Logger.app.warning("StoreManager: handle unknown transaction product type \(transaction.productType.localizedDescription, privacy: .public)")
            break
        }
    }

    // MARK: - Non-Consumable Handling
    private func unlockNonConsumable(for transaction: Transaction) async {
        guard let product = products.first(where: { $0.id == transaction.productID }) else {
            self.disableProLicense()
            Logger.app.error("StoreManager: unlockNonConsumable -> product not found.")
            return
        }

        do {
            try self.enableProLicense(productIdentifier: ProductIdentifier(rawValue: product.id)!)
            purchasedProducts.append(product)
        } catch {
            Logger.app.error("StoreManager: unlockNonConsumable error: \(error.localizedDescription, privacy: .public)")
            return
        }

        Logger.app.info("StoreManager: Unlocked non-consumable product: \(product.displayName, privacy: .public)")
    }

    // MARK: - Subscription Management
    private func handleSubscription(for transaction: Transaction) async {
        guard let product = products.first(where: { $0.id == transaction.productID }) else {
            return
        }

        do {
            let statuses = try await product.subscription?.status
            if let statuses = statuses {
                subscriptionStatus = statuses
                for status in statuses {
                    switch status.state {
                    case .subscribed:
                        purchasedProducts.append(product)
                        try self.enableProLicense(productIdentifier: ProductIdentifier(rawValue: product.id)!)

                        Logger.app.info("StoreManager: User is subscribed to \(product.displayName, privacy: .public)")
                    case .expired:
                        self.disableProLicense()
                        Logger.app.info("StoreManager: Subscription expired for \(product.displayName, privacy: .public)")
                    case .revoked:
                        self.disableProLicense()
                        Logger.app.info("StoreManager: Subscription revoked for \(product.displayName, privacy: .public)")
                    default:
                        self.disableProLicense()
                        break
                    }
                }
            }
        } catch {
            self.disableProLicense()
            Logger.app.error("StoreManager: Failed to handle subscription: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Early Bird User
    /// Check if the customer purchased the paid version, before the switch to IAP
//    func verifyPaidVersion() async throws {
//        do {
//            let shared = try await AppTransaction.shared
//            let transaction = try self.checkVerified(shared)
//
//            // Hard code the version number in which the app's business model changed
//            let addedIAPVersion = "1.0.4" // CFBundleShortVersionString
//            // Get the version number the customer originally purchased
//            let originalAppVersion = transaction.originalAppVersion
//            // Compare version numbers, if original app version is less than addedIAP version
//            // set lifetime access.
//            if originalAppVersion.compare(addedIAPVersion) == .orderedAscending {
//                // existing customer
//                try self.enableProLicense(productIdentifier: .Lifetime)
//
//                Logger.paywall.info("StoreManager: Found previous paid version \(originalAppVersion, privacy: .public) before 1.0.4. Granted lifetime.")
//            }
//        } catch {
//            self.disableProLicense()
//            Logger.paywall.error("StoreManager: verifyPaidVersion error: \(error.localizedDescription, privacy: .public)")
//            throw error
//        }
//    }

    /// Enable pro license and set entitlement name
    /// Sets hasPurchased to true
    /// Sets UserDefaults "hasPro" to true
    /// Sets UserDefaults "currentEntitlement" to passed name
    /// - Parameters:
    ///     - productIdentifier: Annual, Monthly or Lifetime
    /// - throws: StoreError.productNotFound
    private func enableProLicense(productIdentifier: ProductIdentifier) throws {
        Logger.app.info("StoreManager: entitlement name: \(productIdentifier.rawValue)")
        // get purchased product name
        guard let product = self.products.first(where: { $0.id == productIdentifier.rawValue }) else {
            throw StoreError.productNotFound
        }

        hasPurchased = true
        UserDefaults.standard.set(hasPurchased, forKey: "hasPro")
        UserDefaults.standard.set(product.displayName, forKey: "currentEntitlement")
        Logger.app.info("StoreManager: enabled \(product.displayName, privacy: .public) license.")
    }

    /// Disable pro license
    /// Sets hasPurchased to false
    /// Sets UserDefaults "hasPro" to false
    /// Sets UserDefaults "currentEntitlement" to ""
    private func disableProLicense() {
        hasPurchased = false
        UserDefaults.standard.set(false, forKey: "hasPro")
        UserDefaults.standard.set("", forKey: "currentEntitlement")
        Logger.app.info("StoreManager: disabled pro license.")
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}
