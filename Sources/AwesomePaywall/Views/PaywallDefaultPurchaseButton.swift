//
//  PaywallDefaultPurchaseButton.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 13.10.25.
//

import SwiftUI

public struct PaywallDefaultPurchaseButton: View {
    @EnvironmentObject private var store: PaywallStore
    @Environment(\.paywallPurchaseAction) private var purchaseAction

    let foregroundColor: Color
    let backgroundColor: Color

    public init(foregroundColor: Color = .white, backgroundColor: Color = .black) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        Button(action: {
                guard let selectedProduct = store.selectedProduct else { return }
                purchaseAction?(selectedProduct)
            }) {
                HStack {
                    Spacer()
                    if store.isLoading {
                        ProgressView()
                            .tint(foregroundColor)
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
                .foregroundStyle(foregroundColor)
            }
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding()
            .disabled(store.isLoading || store.selectedProduct == nil)
    }
}
