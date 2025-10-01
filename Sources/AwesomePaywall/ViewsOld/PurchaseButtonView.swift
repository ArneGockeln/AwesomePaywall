//
//  PurchaseButtonView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI
import StoreKit

// MARK: - Purchase Button
extension PaywallView {
    struct PurchaseButtonView: View {
        @Binding var isPurchasing: Bool
        @Binding var isFreeTrial: Bool
        @Binding var selectedProduct: Product?
        var onButtonPressed: () -> Void

        @EnvironmentObject private var storeModel: StoreManager

        var body: some View {
            VStack {
                if let product = selectedProduct {
                    Text("Plan auto-renews for \(product.displayPrice)/\(isFreeTrial ? "week" : "year") until canceled.")
                        .font(.footnote)
                }

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
