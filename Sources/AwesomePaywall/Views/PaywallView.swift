//
//  PaywallView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 11.09.25.
//

import StoreKit
import SwiftUI
import OSLog

struct PaywallView: View {
    var backgroundColor: Color = Color.orange
    var highlightColor: Color = Color.red
    @Binding var isPresented: Bool

    // private
    @EnvironmentObject private var storeModel: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var purchaseInProgress: Bool = false
    @State private var progress: CGFloat = 0.0
    @State private var showCloseButton = true
    @State private var freeTrialEnabled: Bool = false
    @State private var showAlert: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading) {

            // Soft Paywall Close Button
            PaywallCloseButtonView(showCloseButton: $showCloseButton, isPresented: $isPresented, progress: $progress)

            Spacer()

            HeroView()

            // Products
            ForEach(storeModel.products, id: \.id) { product in
                PaywallProductView(product: product, selected: $selectedProduct, discount: (product.subscription?.subscriptionPeriod == .yearly ? storeModel.calculateDiscount() : nil), color: self.highlightColor)
            }

            // Trial Row
            TrialRowView(isEnabled: $freeTrialEnabled)

            Spacer()

            // Purchase Button
            PurchaseButtonView(isPurchasing: $purchaseInProgress, isFreeTrial: $freeTrialEnabled) {
                purchaseProduct()
            }

            // Legal Notice
            HStack {
                Spacer()

                RestoreButtonView(isPurchasing: $purchaseInProgress)
                TermsOfUseButton()

                Spacer()
            }
            .padding(.bottom)
        }
        .background(self.backgroundColor)
        .ignoresSafeArea()
        // select freeTrial when product changes
        .onChange(of: selectedProduct) { _, productState in
            guard let newProduct = productState else { return }
            self.freeTrialEnabled = newProduct.hasTrial()
        }
        // select product when freeTrial toggle changes
        .onChange(of: freeTrialEnabled) { _,trialState in
            // if free trial toggle switched on,select weekly plan
            if trialState,
                let selectedProduct,
                selectedProduct.subscription?.subscriptionPeriod == .yearly {
                selectWeeklyPlan()
                return
            }

            // if free trial toggle switched off, select yearly plan
            if !trialState,
                let selectedProduct,
                selectedProduct.subscription?.subscriptionPeriod == .weekly {
                selectYearlyPlan()
            }
        }
        // present purchase error
        .alert("Error", isPresented: $showAlert) {
            Button("OK") {
                self.errorMessage = nil
            }
        } message: {
            Text(self.errorMessage ?? "")
        }
        // select yearly plan on appear
        .onAppear {
            selectYearlyPlan()
        }
    }

    private func selectYearlyPlan() {
        self.selectedProduct = storeModel.products.first(where: { $0.subscription?.subscriptionPeriod == .yearly })
    }

    private func selectWeeklyPlan() {
        self.selectedProduct = storeModel.products.first(where: { $0.subscription?.subscriptionPeriod == .weekly })
    }

    /// Purchase the selected product
    private func purchaseProduct() {
        Task {
            self.purchaseInProgress = true
            do {
                guard let product = self.selectedProduct else {
                    throw PaywallViewError.productNotSelected
                }

                await self.storeModel.purchase(product)
                UserDefaults.standard.set(self.storeModel.hasPurchased, forKey: "hasPro")
                self.isPresented = false
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.purchaseInProgress = false
        }
    }
}

// MARK: - Paywall Close Button View
extension PaywallView {
    struct PaywallCloseButtonView: View {
        @Binding var showCloseButton: Bool
        @Binding var isPresented: Bool
        @Binding var progress: CGFloat

        var body: some View {
            HStack {
                Spacer()

                if !showCloseButton {
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .opacity(0.1 + 0.1 * self.progress)
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "multiply")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, alignment: .center)
                        .clipped()
                        .onTapGesture {
                            isPresented = false
                        }
                        .opacity(0.2)
                }
            }
            .padding(.top, 60)
            .padding(.trailing, 30)
        }
    }
}

// MARK: - Hero View
extension PaywallView {
    struct HeroView: View {
        var body: some View {
            VStack {
                // Title
                HStack {
                    Spacer()
                    TitleView()
                    Spacer()
                }

//                PushupAnimationView(showPhone: true)

                VStack(alignment: .leading) {
                    FeatureRow(icon: "list.star", text: "Unlock All Modes")
//                    FeatureRow(icon: "person.3.fill", text: "Unlock Leaderboard")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Unlock Progress Statistics")
                    FeatureRow(icon: "lock.square.stack", text: "Remove anoying paywalls")
                }
            }
            .padding()
        }

        // Title View
        struct TitleView: View {
            var body: some View {
                ZStack {
                    Text("PushUp Battle")
                        .font(.system(size: 40))
                        .bold()

                    Text("Pro")
                        .foregroundStyle(Color.white)
                        .font(.title.bold())
                        .padding(6)
                        .background {
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundStyle(Color.red)
                        }
                        .rotationEffect(.degrees(10))
                        .padding(.top, 70)

                }
            }
        }

        /// Feature Row
        struct FeatureRow: View {
            let icon: String
            let text: String

            var body: some View {
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .overlay {
                            Image(systemName: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20, alignment: .center)
                                .clipped()
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white)
                                .padding(3)
                        }
                        .frame(width: 30, height: 30)

                    Text(text)
                }
                .font(.system(size: 16, weight: .medium))
            }
        }
    }
}

// MARK: - Trial Row
extension PaywallView {
    struct TrialRowView: View {
        @Binding var isEnabled: Bool

        var body: some View {
            HStack {
                Toggle(isOn: $isEnabled) {
                    Text("Free Trial Enabled")
                        .font(.headline.bold())
                }
                .padding(.horizontal)
                .tint(Color.red)
            }
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
        }
    }
}

// MARK: - Paywall Product
extension PaywallView {
    struct PaywallProductView: View {
        var product: Product
        @Binding var selected: Product?
        var discount: Int?
        var color: Color // highlight color

        @State private var isSelected: Bool = false

        var body: some View {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(.headline.bold())
                        Text(priceFormatted)
                            .font(.footnote)
                    }

                    Spacer()

                    // discount badge
                    if let discount {
                        DiscountBadgeView(discount: discount)
                            .padding(.trailing, 5)
                    }

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? color : Color.secondary)
                }
                .padding(10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? color : Color.primary.opacity(0.15), lineWidth: 1)

                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(isSelected ? color.opacity(0.05) : Color.primary.opacity(0.005))
                }
            }
            .padding(.horizontal)
            .onTapGesture {
                self.selected = product
            }
            .onChange(of: selected) { _, newProduct in
                guard let prod = newProduct else { return }
                self.isSelected = prod == product
            }
        }

        private var periodName: String {
            get {
                switch product.subscription?.subscriptionPeriod {
                    case .yearly: "year"
                    case .monthly: "month"
                    case .weekly: "week"
                    default: ""
                }
            }
        }

        private var priceFormatted: String {
            get {
                if product.hasTrial() {
                    "3 days free trial then \(product.displayPrice) per \(periodName)"
                } else {
                    "\(product.displayPrice) per \(periodName)"
                }
            }
        }


    }
}

// MARK: - Purchase Button
extension PaywallView {
    struct PurchaseButtonView: View {
        @Binding var isPurchasing: Bool
        @Binding var isFreeTrial: Bool
        var onButtonPressed: () -> Void

        @EnvironmentObject private var storeModel: StoreManager

        var body: some View {
            VStack {
                if isPurchasing {
                    HStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                            .foregroundStyle(Color.black)
                        Spacer()
                    }
                } else {
                    Button(action: {
                        // Start subscription
                        onButtonPressed()
                    }) {
                        HStack {
                            Spacer()
                            HStack {
                                Text(isFreeTrial ? "Start Free Trial" : "Unlock Now")
                                Image(systemName: "chevron.right")
                            }
                            Spacer()
                        }
                        .padding()
                        .foregroundStyle(Color.white)
                        .font(.title3.bold())
                    }
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal)
                }
            }
            .padding(.top)
            .padding(.bottom, 4)
        }
    }
}

// MARK: - Restore Button
extension PaywallView {
    struct RestoreButtonView: View {
        @State private var showNoneRestoreAlert: Bool = false
        @EnvironmentObject private var storeModel: StoreManager
        @Binding var isPurchasing: Bool

        var body: some View {
            Button("Restore") {
                // storeModel try to restore
                restorePurchase()
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .foregroundStyle(Color.black.opacity(0.5))
            .font(.footnote)
            .alert("Restore failed", isPresented: $showNoneRestoreAlert) {
                Button("OK", role: .destructive) {
                    self.isPurchasing = false
                }
            } message: {
                Text("No purchases restored.")
            }
        }

        /// Restore previous purchases
        private func restorePurchase() {
            Task {
                self.isPurchasing = true
                await self.storeModel.restorePurchases()
                self.isPurchasing = false

                if !self.storeModel.hasPurchased {
                    self.showNoneRestoreAlert = true
                }
            }
        }
    }
}

// MARK: - Terms of Use Button
extension PaywallView {
    struct TermsOfUseButton: View {
        @State private var showTermsActionSheet: Bool = false

        var body: some View {
            Button("Terms of Use & Privacy Policy") {
                showTermsActionSheet = true
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .foregroundStyle(Color.black.opacity(0.5))
            .font(.footnote)
            .confirmationDialog(Text("View Terms & Conditions"), isPresented: $showTermsActionSheet) {
                Button("Terms of Use") {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }

                Button("Privacy Policy") {
                    if let url = URL(string: "https://arnesoftware.com/privacy") {
                        UIApplication.shared.open(url)
                    }
                }
            }

        }
    }
}

enum PaywallViewError: Error {
    case productNotSelected
}

struct DiscountBadgeView: View {
    let discount: Int

    var body: some View {
        Text("SAVE \(discount)%")
            .foregroundStyle(Color.white)
            .font(.caption.bold())
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(Color.red)
            }
    }
}


#Preview {
//    TitleView()
//    DiscountBadgeView(discount: 68)
    PaywallView(isPresented: .constant(true))
        .environmentObject(StoreManager.shared)
}
