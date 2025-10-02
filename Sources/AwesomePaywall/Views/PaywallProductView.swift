//
//  PaywallProductView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI
import StoreKit

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
