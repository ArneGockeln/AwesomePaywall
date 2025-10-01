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
    let marketingView: () -> V

    enum PresentedSheet: Identifiable {
        var id: Self { self }
        case privacy, terms
    }

    @EnvironmentObject private var apStore: APStore
    @State private var selectedProduct: Product?
    @State private var isSheetPresented: PresentedSheet?

    var body: some View {
        ScrollView {
            closeButton()
            marketingView()

            VStack {
                if apStore.products.isEmpty {
                    ProgressView()
                } else {
                    ForEach(apStore.products) { product in
                        PaywallProductView(product: product, selected: $selectedProduct, color: Color.black) {
                            EmptyView()
//                            if product.subscription?.subscriptionPeriod == .yearly,
//                                let discount = self.calculateDiscount(for: product) {
//                                DiscountBadgeView(discount: discount, backgroundColor: config.backgroundColor)
//                                    .padding(.vertical, 4)
//                            } else {
//                                EmptyView()
//                            }
                        }
                        .onAppear {
                            // Select yearly product
                            guard product.subscription?.subscriptionPeriod == .yearly else {
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
        .background(config.backgroundColor)
    }

//    private func calculateDiscount(for product: Product) -> Int? {
//        guard product.subscription?.subscriptionPeriod == .yearly,
//              let weekly = apStore.products.first(where: { $0.subscription?.subscriptionPeriod == .weekly })?.price else {
//            return nil
//        }
//
//        let yearly = product.price
//        let weeklyPerYear = weekly * 4 * 12
//        let discount = (100.0 - (yearly / weeklyPerYear * 100.0)).rounded(1, .bankers).toInt()
//
//        logger.debug("CalculateDiscount: \(discount)%")
//
//        return discount
//    }

    @ViewBuilder
    private func termsAndServices() -> some View {
        HStack {
            Button(action: {
                Task {
                    await apStore.restorePurchases()
                }
            }) {
                Text("Restore Purchase")
                    .font(.footnote.bold())
            }

            Text("•")

            Button(action: { isSheetPresented = .terms }) {
                Text("Terms of Use")
                    .font(.footnote.bold())
            }
            .buttonStyle(.plain)

            Text("•")

            Button(action: { isSheetPresented = .privacy }) {
                Text("Privacy Policy")
                    .font(.footnote.bold())
            }
            .buttonStyle(.plain)
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
                        Text("Unlock Now")
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

extension AwesomePaywallView {
    struct XMarkButtonView: View {
        var body: some View {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.all, 5)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .accessibilityLabel(Text("Close"))
                .accessibilityHint(Text("Tap to close the sheet"))
                .accessibilityAddTraits(.isButton)
                .accessibilityRemoveTraits(.isImage)
        }
    }

    struct AwesomeWebView: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> WKWebView {
            return WKWebView()
        }

        func updateUIView(_ webView: WKWebView, context: Context) {
            let request = URLRequest(url: self.url)
            webView.load(request)
        }
    }

    struct DiscountBadgeView: View {
        let discount: Int
        let backgroundColor: Color

        var body: some View {
            Text("SAVE \(discount)%")
                .foregroundStyle(Color.black)
                .font(.caption.bold())
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(backgroundColor)
                }
        }
    }

    struct PaywallProductView<DiscountContent: View>: View {
        let product: Product
        @Binding var selected: Product?
        let color: Color // highlight color
        @ViewBuilder let discountView: DiscountContent

        var body: some View {
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(product.displayPrice) \(product.displayName)")
                                .font(.headline.bold())

                            // discount badge
                            discountView
                        }
                        Text(product.description)
                            .font(.footnote)
                    }

                    Spacer()

                    Image(systemName: isSelected() ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected() ? color : Color.secondary)
                }
                .padding(10)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected() ? color : Color.primary.opacity(0.15), lineWidth: 1)

                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(isSelected() ? color.opacity(0.05) : Color.primary.opacity(0.005))
                }
            }
            .padding(.horizontal)
            .onTapGesture {
                self.selected = product
            }
        }

        // Change view when product is selected
        private func isSelected() -> Bool {
            guard let selectedProduct = self.selected else { return false }
            return selectedProduct.id == self.product.id
        }
    }
}
