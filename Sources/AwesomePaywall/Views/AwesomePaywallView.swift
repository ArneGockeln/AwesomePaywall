//
//  SK2Paywall.swift
//  PushupBattle
//
//  Created by Arne Gockeln on 28.09.25.
//

import SwiftUI
import StoreKit
import WebKit
import OSLog

private let log = Logger(subsystem: "com.arnegockeln.PushUpBattle", category: "Paywall")

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

                LazyVStack {
                    if apStore.isLoading {
                        ProgressView()
                    } else {
                        ForEach($apStore.products, id: \.id) { $product in
                            self.productView(for: product)
                                .onAppear {
                                    // Select yearly product
                                    guard !isWeeklySelected(product: product) else {
                                        return
                                    }
                                    self.selectedProduct = product
                                }
                        }
                    }
                }

                purchaseButton()
                termsAndServices()
            }
            .padding(.bottom)
        }
        .ignoresSafeArea()
    }

    private func isProductSelected(_ product: Product) -> Bool {
        guard let selectedProduct else { return false }
        return product.id == selectedProduct.id
    }

    private func weeklyProduct() -> Product? {
        guard let weekly = self.apStore.products.last else {
            return nil
        }
        return weekly
    }

    private func calculateDiscount(for product: Product) -> Int? {
        guard product.subscription?.subscriptionPeriod.unit == .year else {
            return nil
        }

        guard let weekly = weeklyProduct()?.price else {
            return nil
        }

        let yearly = product.price
        let weeklyPerYear = weekly * 4 * 12
        let discount = (100.0 - (yearly / weeklyPerYear * 100.0)).rounded(1, .bankers).toInt()

        return discount
    }

    private func isWeeklySelected(product: Product?) -> Bool {
        guard let selectedProduct = product else { return false }
        return selectedProduct.subscription?.subscriptionPeriod.unit == .week
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
                        if isWeeklySelected(product: self.selectedProduct) {
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
