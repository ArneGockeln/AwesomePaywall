//
//  PaywallProductView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import StoreKit
import SwiftUI

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
