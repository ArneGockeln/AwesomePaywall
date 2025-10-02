//
//  SK2Paywall.swift
//  PushupBattle
//
//  Created by Arne Gockeln on 28.09.25.
//

import SwiftUI
import StoreKit
import WebKit

struct AwesomePaywallView<V: View>: View {
    let config: APConfiguration
    @ViewBuilder let marketingView: () -> V

    enum PresentedSheet: Identifiable {
        var id: Self { self }
        case privacy, terms
    }

    @EnvironmentObject private var apStore: APStore
    @State private var selectedProduct: Product?
    @State private var isSheetPresented: PresentedSheet?
    @State private var isWeeklyProductSelected: Bool = false

    var body: some View {
        ZStack {
            config.backgroundColor

            VStack {
                closeButton()
                    .padding(.trailing, 10)
                    .padding(.top, 60)

                Spacer()

                marketingView()

                Spacer()

                ForEach($apStore.products, id: \.id) { $product in
                    self.productView(for: product)
                }

                purchaseButton()
                termsAndServices()
            }
            .padding(.bottom)
        }
        .ignoresSafeArea()
        .onAppear {
            // select yearly product
            guard let firstProduct = self.apStore.products.first else {
                return
            }
            selectYearly(firstProduct)
        }
        .onChange(of: self.selectedProduct) { _,newProduct in
            // if weekly product is selected, update button text
            guard let prod = newProduct else {
                return
            }

            guard let period = prod.subscription?.subscriptionPeriod else {
                return
            }

            if period == Product.SubscriptionPeriod.weekly {
                self.isWeeklyProductSelected = true
            } else {
                self.isWeeklyProductSelected = false
            }
        }
    }

    // Used in onAppear of products.forEach
    private func selectYearly(_ product: Product) {
        guard product.subscription?.subscriptionPeriod == Product.SubscriptionPeriod.yearly else {
            return
        }
        self.selectedProduct = product
    }

    // Used in productView()
    private func isProductSelected(_ product: Product) -> Bool {
        guard let selectedProduct else { return false }
        return product.id == selectedProduct.id
    }

    // Used in productView()
    private func calculateDiscount(for product: Product) -> Int? {
        guard product.subscription?.subscriptionPeriod.unit == .year,
              let weekly = self.apStore.products.last?.price else {
            return nil
        }

        let yearly = product.price
        let weeklyPerYear = weekly * 4 * 12
        let discount = (100.0 - (yearly / weeklyPerYear * 100.0)).rounded(1, .bankers).toInt()

        return discount
    }

    // Check if self.selectedProduct equals period
    // Used in purchaseButton
    private func isSelected(period: Product.SubscriptionPeriod) -> Bool {
        guard let product = self.selectedProduct,
              product.subscription?.subscriptionPeriod == period else {
            return false
        }
        return true
    }
}

extension AwesomePaywallView {
    @ViewBuilder
    private func productView(for product: Product) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(product.displayPrice) \(product.displayName)")
                        .font(.headline.bold())

                    if let discount = self.calculateDiscount(for: product) {
                        DiscountBadgeView(discount: discount, backgroundColor: config.backgroundColor)
                    }
                }

                Text(product.description)
                    .font(.footnote)
            }
            .padding([.vertical, .leading], 8)

            Spacer()

            Image(systemName: isProductSelected(product) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isProductSelected(product) ? config.foregroundColor : Color.secondary)
                .padding(.trailing, 8)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(isProductSelected(product) ? config.foregroundColor : config.backgroundColor, lineWidth: 2)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
        .onTapGesture {
            self.selectedProduct = product
        }
    }
}

extension AwesomePaywallView {
    @ViewBuilder
    private func legalButton(text: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.footnote.bold())
        }
        .buttonStyle(.plain)
    }
}

extension AwesomePaywallView {
    @ViewBuilder
    private func purchaseButton() -> some View {
        Button(action: {
            Task {
                guard let selectedProduct = selectedProduct else { return }
                try? await apStore.purchase(selectedProduct)
            }
        }) {
            HStack {
                Spacer()
                if apStore.isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    HStack {
                        if self.isWeeklyProductSelected {
                            Text("Start Free Trial")
                        } else {
                            Text("Unlock Now")
                        }
                        Image(systemName: "chevron.right")
                    }
                }
                Spacer()
            }
            .font(.title3.bold())
            .padding()
            .foregroundStyle(Color.white)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding()
        .disabled(apStore.isLoading || selectedProduct == nil)
    }
}

extension AwesomePaywallView {
    @ViewBuilder
    private func termsAndServices() -> some View {
        HStack {
            legalButton(text: "Restore Purchase") {
                Task {
                    await apStore.restorePurchases()
                }
            }

            Text("•")

            legalButton(text: "Terms of Use") {
                isSheetPresented = .terms
            }

            Text("•")

            legalButton(text: "Privacy Policy") {
                isSheetPresented = .privacy
            }
        }
        .padding([.horizontal, .bottom])
        .sheet(item: $isSheetPresented) { sheet in
            VStack {
                HStack {
                    Spacer()

                    Button(action: { isSheetPresented = nil }) {
                        XMarkButtonView()
                    }
                    .buttonStyle(.plain)
                    .padding()
                }

                AwesomeWebView(url: sheet == .privacy ? config.privacyUrl : config.termsOfServiceUrl)
            }
        }
    }
}

extension AwesomePaywallView {
    @ViewBuilder
    private func closeButton() -> some View {
        HStack {
            Spacer()

            Button(action: { apStore.isPaywallPresented = false }) {
                XMarkButtonView()
                    .opacity(0.4)
            }
            .padding(.trailing)
        }
    }
}

#Preview {
    @Previewable @StateObject var apStore = APStore()
    AwesomePaywallView(config: APConfiguration(
        productIDs: ["PushUpBattlePro.Annual", "PushUpBattlePro.Weekly"],
        privacyUrl: URL(string: "https://arnesoftware.com/privacy")!,
        termsOfServiceUrl: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        backgroundColor: Color.gray,
        foregroundColor: Color.black
    )) {
        Text("Marketing View")
    }
    .environmentObject(apStore)
    .task {
        await apStore.configure(productIDs: ["PushUpBattlePro.Annual", "PushUpBattlePro.Weekly"])
    }
}
