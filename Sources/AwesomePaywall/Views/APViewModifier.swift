//
//  APViewModifier.swift
//  PushupBattle
//
//  Created by Arne Gockeln on 30.09.25.
//

import SwiftUI
import StoreKit

struct APViewModifier<V: View>: ViewModifier where V: View {
    @StateObject private var store = APStore()

    let productIDs: [String]
    let privacyUrl: URL
    let termsOfServiceUrl: URL
    let marketingView: () -> V

    func body(content: Content) -> some View {
        content
            // show full screen paywall
            .fullScreenCover(isPresented: $store.isPaywallPresented) {
                SK2Paywall(privacyUrl: privacyUrl, termsOfServiceUrl: termsOfServiceUrl) {
                    marketingView()
                }
            }
            // configure the store
            .task(priority: .background) {
                await store.configure(productIDs: productIDs)
            }
            // hide paywall when pro subscription was activated
            .onChange(of: store.hasProSubscription) { _, newState in
                store.isPaywallPresented = !newState
            }
            // publish the store
            .environmentObject(store)
    }
}

extension View {
    // Attach an Awesome Paywall for product ids to the view and initialise an observable store.
    func awesomePaywall<V>(for productIDs: [String], termsOfServiceUrl: URL, privacyPolicyUrl: URL, marketingView: @escaping () -> V) -> some View where V: View {
        modifier(APViewModifier(productIDs: productIDs, privacyUrl: privacyPolicyUrl, termsOfServiceUrl: termsOfServiceUrl, marketingView: marketingView))
    }
}
