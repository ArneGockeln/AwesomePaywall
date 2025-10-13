//
//  DefaultPaywallTemplate.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 12.10.25.
//

import SwiftUI
import StoreKit

public struct PaywallDefaultTemplate: View {
    @EnvironmentObject private var store: PaywallStore

    @Environment(\.paywallRestoreAction) private var restoreAction
    @Environment(\.paywallLegalSheetAction) private var legalSheetAction
    @Environment(\.paywallPurchaseAction) private var purchaseAction
    @Environment(\.paywallToggleAction) private var toggleAction

    let title: LocalizedStringKey
    let features: [PaywallDefaultFeature]

    public var body: some View {
        WithBackgroundColor(color: Color.white, asGradient: true, gradientStart: .top, gradientStop: .bottom) {
            VStack {
                closeButton()

                Spacer()

                HStack {
                    Spacer()
                    TitleView(title: title)
                    Spacer()
                }

                VStack(alignment: .leading) {
                    ForEach(features, id: \.id) { feature in
                        FeatureRow(systemImageName: feature.systemImageName, text: feature.title)
                    }
                }

                Spacer()

                ForEach($store.products, id: \.id) { $product in
                    self.makeProductView(for: product)
                }

                purchaseButton()
                termsAndServices()
            }
        }
        .task {
            await store.select(by: .yearly)
        }
    }

    // Title View
    struct TitleView: View {
        let title: LocalizedStringKey

        var body: some View {
            ZStack {
                Text(title)
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
                    .rotationEffect(.degrees(-10))
                    .padding(.top, 70)

            }
        }
    }

    /// Feature Row
    struct FeatureRow: View {
        let systemImageName: String
        let text: LocalizedStringKey

        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .overlay {
                        Image(systemName: systemImageName)
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

extension PaywallDefaultTemplate {
    @ViewBuilder
    private func makeProductView(for product: Product) -> some View {
        ProductRow(product: product)
    }
}

extension PaywallDefaultTemplate {
    struct ProductRow: View {
        @EnvironmentObject private var store: PaywallStore
        let product: Product
        @State private var discount: Int?

        var body: some View {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(product.displayPrice) \(product.displayName)")
                            .font(.headline.bold())

                        if let discount = discount {
                            DiscountBadgeView(discount: discount, backgroundColor: Color.red)
                                .foregroundStyle(Color.white)
                        }
                    }

                    Text(product.description)
                        .font(.footnote)
                }
                .padding([.vertical, .leading], 8)

                Spacer()

                Image(systemName: store.isSelected(product) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(store.isSelected(product) ? Color.black : Color.secondary)
                    .padding(.trailing, 8)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(store.isSelected(product) ? Color.black : Color.gray, lineWidth: 2)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            .onTapGesture {
                store.selectedProduct = product
            }
            .task {
                if let value = await store.calculateDiscount(for: product) {
                    discount = value
                }
            }
        }
    }
}

extension PaywallDefaultTemplate {
    @ViewBuilder
    private func legalButton(text: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.footnote.bold())
        }
        .buttonStyle(.plain)
    }
}

extension PaywallDefaultTemplate {
    @ViewBuilder
    private func purchaseButton() -> some View {
        Button(action: {
            guard let selectedProduct = store.selectedProduct else { return }
            purchaseAction?(selectedProduct)
        }) {
            HStack {
                Spacer()
                if store.isLoading {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    HStack {
                        if store.isSelected(period: .weekly) {
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
        .disabled(store.isLoading || store.selectedProduct == nil)
    }
}

extension PaywallDefaultTemplate {
    @ViewBuilder
    private func termsAndServices() -> some View {
        HStack {
            legalButton(text: "Restore Purchase") {
                restoreAction?()
            }

            Text("•")

            legalButton(text: "Terms of Use") {
                legalSheetAction?(.terms)
            }

            Text("•")

            legalButton(text: "Privacy Policy") {
                legalSheetAction?(.privacy)
            }
        }
        .padding([.horizontal, .bottom])
    }
}

extension PaywallDefaultTemplate {
    @ViewBuilder
    private func closeButton() -> some View {
        HStack {
            Spacer()

            Button(action: { toggleAction?() }) {
                XMarkButtonView()
                    .opacity(0.4)
            }
            .padding(.trailing)
        }
        .padding(.trailing, 10)
        .padding(.top, 60)
    }
}

#Preview {
    @Previewable @StateObject var store = PaywallStore()
    PaywallDefaultTemplate(
        title: "Your Awesome App",
        features: [
            .init(systemImageName: "list.star", title: "Unlimited Features"),
            .init(systemImageName: "widget.large", title: "Become the X-Wing Copilot"),
            .init(systemImageName: "lock.square.stack", title: "Remove Anoying Paywalls")
        ]
    )
        .environmentObject(store)
        .task {
            await store.configure(productIDs: ["YourAppPro.Weekly", "YourAppPro.Annual"])
        }
}

