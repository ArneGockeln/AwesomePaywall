//
//  StoreManager.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 11.09.25.
//

import StoreKit

@MainActor
public final class StoreManager: ObservableObject {
    public static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []
    @Published var subscriptionStatus: [Product.SubscriptionInfo.Status] = []
    @Published var hasPurchased: Bool = false

    @Published var errorMessages: [String] = []

    // store product identifiers from AppStore Connect
    private var productIdentifiers: [String] = []
    // store terms of use url
    public var termsOfUseUrl: String?
    // store privacy policy url
    public var privacyPolicyUrl: String?

    // Quick check if the current user has purchased
    public func isPayingCustomer() -> Bool {
        return hasPurchased
    }

    private var updateTask: Task<Void, Never>? = nil

    private init() {
        updateTask = listenForTransactionUpdates()
    }

    deinit {
        updateTask?.cancel()
    }

    /// Fetch products from the app store and load current entitlements
    /// This should only run once. If needed set force to true and it will run again.
    public func configure(productIdentifiers: [String], termsOfUseUrl: String? = nil, privacyUrl: String? = nil,  force: Bool = false) async {
        if force || self.products.isEmpty {
            self.productIdentifiers = productIdentifiers
            self.errorMessages = []
            self.termsOfUseUrl = termsOfUseUrl
            self.privacyPolicyUrl = privacyUrl
            await fetchProducts()
            await loadCurrentEntitlements()
        }
    }

    // MARK: - Calculate Discount based on weekly and yearly price
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
                    Log.shared.info("Transaction was successful.")
            case let .success(.unverified(_, error)):
                /// Success but unverified transaction
                    Log.shared.info("Transaction was successful but unverified: \(error)")
            case .pending:
                /// Pending order
                    Log.shared.info("Transaction is pending.")
            case .userCancelled:
                /// User cancelled through purchase process
                    Log.shared.info("Transaction was cancelled.")
            @unknown default:
                /// Something different happened
                    Log.shared.info("Unknown purchase result.")
            }
        } catch {
            self.disableProLicense()
            Log.shared.error("Purchase failed: \(error)")
        }
    }

    /// Restore Purchases and validate entitlements
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await loadCurrentEntitlements()
        } catch {
            Log.shared.error("Restore Purchase error: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Products
    private func fetchProducts() async {
        do {
            // Fetch products from the App Store
            products = try await Product.products(for: self.productIdentifiers)

            // Sort by price
            products.sort(by: { $0.price > $1.price })
        } catch {
            self.disableProLicense()
            self.errorMessages.append("StoreManager: Failed to fetch products: \(error)")
            Log.shared.error("Failed to fetch products: \(error)")
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
            Log.shared.error("Failed to load current entitlements: \(error)")
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
                    await Log.shared.error("Failed to verify transaction: \(error.localizedDescription)")
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
                Log.shared.info("handle unknown transaction product type \(transaction.productType.localizedDescription)")
            break
        }
    }

    // MARK: - Non-Consumable Handling
    private func unlockNonConsumable(for transaction: Transaction) async {
        guard let product = products.first(where: { $0.id == transaction.productID }) else {
            self.disableProLicense()
            Log.shared.error("unlockNonConsumable -> product not found.")
            return
        }

        do {
            try self.enableProLicense(for: product.id)
            purchasedProducts.append(product)
        } catch {
            Log.shared.error("unlockNonConsumable error: \(error.localizedDescription)")
            return
        }

        Log.shared.info("Unlocked non-consumable product: \(product.displayName)")
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
                        try self.enableProLicense(for: product.id)

                            Log.shared.info("User is subscribed to \(product.displayName)")
                    case .expired:
                        self.disableProLicense()
                            Log.shared.info("Subscription expired for \(product.displayName)")
                    case .revoked:
                        self.disableProLicense()
                            Log.shared.info("Subscription revoked for \(product.displayName)")
                    default:
                        self.disableProLicense()
                        break
                    }
                }
            }
        } catch {
            self.disableProLicense()
            Log.shared.error("Failed to handle subscription: \(error.localizedDescription)")
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
//                Logger.paywall.info("StoreManager: Found previous paid version \(originalAppVersion) before 1.0.4. Granted lifetime.")
//            }
//        } catch {
//            self.disableProLicense()
//            Logger.paywall.error("StoreManager: verifyPaidVersion error: \(error.localizedDescription)")
//            throw error
//        }
//    }

    /// Enable pro license and set entitlement name
    /// Sets hasPurchased to true
    /// Sets UserDefaults "hasPro" to true
    /// Sets UserDefaults "currentEntitlement" to passed name
    /// - Parameters:
    ///     - productIdentifier: AppNamePro.Annual, AppNamePro.Monthly, AppNamePro.Weekly or AppNamePro.Lifetime
    /// - throws: StoreError.productNotFound
    private func enableProLicense(for productIdentifier: String) throws {
        Log.shared.info("entitlement name: \(productIdentifier)")
        // get purchased product name
        guard let product = self.products.first(where: { $0.id == productIdentifier }) else {
            throw StoreError.productNotFound
        }

        hasPurchased = true
        UserDefaults.standard.set(hasPurchased, forKey: "hasPro")
        UserDefaults.standard.set(product.displayName, forKey: "currentEntitlement")
        Log.shared.info("enabled \(product.displayName) license.")
    }

    /// Disable pro license
    /// Sets hasPurchased to false
    /// Sets UserDefaults "hasPro" to false
    /// Sets UserDefaults "currentEntitlement" to ""
    private func disableProLicense() {
        hasPurchased = false
        UserDefaults.standard.set(false, forKey: "hasPro")
        UserDefaults.standard.set("", forKey: "currentEntitlement")
        Log.shared.info("disabled pro license.")

    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
}
