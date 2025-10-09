//
//  APViewModifier.swift
//  PushupBattle
//
//  Created by Arne Gockeln on 30.09.25.
//

import SwiftUI
import StoreKit
import OSLog

private let logger = Logger(subsystem: "com.arnegockeln.PushUpBattle", category: "AwesomePaywall")

struct APViewModifier<V: View>: ViewModifier where V: View {
    @StateObject private var store = APStore()

    let config: APConfiguration
    let marketingView: () -> V

    func body(content: Content) -> some View {
        content
            // show full screen paywall
            .fullScreenCover(isPresented: $store.isPaywallPresented) {
                AwesomePaywallView(config: config) {
                    marketingView()
                }
            }
            // configure the store
            .task(priority: .background) {
                await store.configure(productIDs: config.productIDs)
            }
            // hide paywall when pro subscription was activated
            .onChange(of: store.hasProSubscription) { _, newState in
                store.isPaywallPresented = !newState
            }
            // Errors
            .onChange(of: store.errors) { _, errorList in
                guard !errorList.isEmpty else { return }
                errorList.forEach { error in
                    logger.error("PaywallError: \(error)")
                }
            }
            // set environment key
            .environment(\.hasProSubscription, store.hasProSubscription)
            // publish the store
            .environmentObject(store)
    }
}

public extension View {
    // Attach an Awesome Paywall for product ids to the view and initialise an observable store.
    func awesomePaywall<V>(with config: APConfiguration, marketingView: @escaping () -> V) -> some View where V: View {
        modifier(APViewModifier(config: config, marketingView: marketingView))
    }
}
