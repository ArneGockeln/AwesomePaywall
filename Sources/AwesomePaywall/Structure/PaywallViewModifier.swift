//
//  APViewModifier.swift
//  PushupBattle
//
//  Created by Arne Gockeln on 30.09.25.
//

import SwiftUI
import StoreKit

struct PaywallViewModifier<Template: View>: ViewModifier where Template: View {
    @StateObject private var store = PaywallStore()

    let config: PaywallConfiguration
    let template: () -> Template
    @State private var error: String?

    func body(content: Content) -> some View {
        content
            // show full screen paywall
            .fullScreenCover(isPresented: $store.isPaywallPresented) {
                PaywallTemplateWrapper(config: config, template: template)
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
            .errorAlert(error: $store.error)
            // set environment key for subscription status
            .environment(\.hasProSubscription, store.hasProSubscription)
            // set environment key for paywall restore action
            .environment(\.paywallRestoreAction) {
                Task {
                    await store.restorePurchases()
                }
            }
            // purchase action
            .environment(\.paywallPurchaseAction) { product in
                Task {
                    try? await store.purchase(product)
                }
            }
            // toggle paywall visibility
            .environment(\.paywallToggleAction) {
                store.isPaywallPresented.toggle()
            }
            // publish the store
            .environmentObject(store)
    }
}

public extension View {
    // Attach an Awesome Paywall with custom paywall template.
    func awesomePaywall<Template>(with config: PaywallConfiguration, template: @escaping () -> Template) -> some View where Template: View {
        modifier(PaywallViewModifier(config: config, template: template))
    }

    // Attach an Awesome Paywall with default Paywall Template.
    func awesomePaywall(with config: PaywallConfiguration, title: LocalizedStringKey, features: [PaywallDefaultFeature]) -> some View {
        modifier(PaywallViewModifier(config: config, template: {PaywallDefaultTemplate(title: title, features: features)}))
    }
}

#if DEBUG
struct PaywallDemo: View {
    var body: some View {
        VStack {
            ToggleButton()
        }
        .awesomePaywall(
            with: PaywallConfiguration(
                productIDs: ["YourAppPro.Annual", "YourAppPro.Weekly"],
                privacyUrl: URL(string: "https://arnesoftware.com/privacy")!,
                termsOfServiceUrl: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
            )) {
                PaywallDefaultTemplate(
                    title: "Your Awesome App",
                    features: [
                        .init(systemImageName: "list.star", title: "Unlimited Features"),
                        .init(systemImageName: "widget.large", title: "Become the X-Wing Copilot"),
                        .init(systemImageName: "lock.square.stack", title: "Remove Anoying Paywalls")
                    ]
                )
            }
    }

    struct ToggleButton: View {
        @Environment(\.paywallToggleAction) var paywallToggleAction

        var body: some View {
            Button(action: { paywallToggleAction?() }) {
                Text("Toggle Paywall")
            }
        }
    }
}

#Preview {
    PaywallDemo()
}
#endif
