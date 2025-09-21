//
//  PaywallView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 11.09.25.
//

import StoreKit
import SwiftUI

struct PaywallView<ViewContent: View>: View {
    @Binding var isPresented: Bool
    var backgroundColor: Color = Color.orange
    var highlightColor: Color = Color.blue
    let heroView: () -> ViewContent

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

            // hero view from viewbuilder
            heroView()

            Spacer()

            // Products
            ForEach(storeModel.products, id: \.id) { product in
                PaywallProductView(product: product, selected: $selectedProduct, discount: (product.subscription?.subscriptionPeriod == .yearly ? storeModel.calculateDiscount() : nil), color: self.highlightColor)
            }

            // Trial Row
            TrialRowView(isEnabled: $freeTrialEnabled, highlightColor: highlightColor)

            // Purchase Button
            PurchaseButtonView(isPurchasing: $purchaseInProgress, isFreeTrial: $freeTrialEnabled) {
                purchaseProduct()
            }

            // Legal Notice
            HStack {
                Spacer()

                RestoreButtonView(isPurchasing: $purchaseInProgress)
                TermsOfUseButton(privacyUrl: storeModel.privacyPolicyUrl, termsOfUseUrl: storeModel.termsOfUseUrl)

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

#Preview {
    PaywallView(isPresented: .constant(true)) {
        Text("Hero")
    }
    .environmentObject(StoreManager.shared)
}
