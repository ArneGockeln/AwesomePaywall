//
//  PaywallDefaultProductList.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 13.10.25.
//

import SwiftUI
import StoreKit

public struct PaywallDefaultProductList: View {
    @EnvironmentObject private var store: PaywallStore

    public init() {
        
    }

    public var body: some View {
        VStack {
            ForEach($store.products, id: \.id) { $product in
                ProductRow(product: product)
            }
        }
    }
}

extension PaywallDefaultProductList {
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
