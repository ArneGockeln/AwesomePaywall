//
//  ContentView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI
import AwesomePaywall

struct ContentView: View {
    // Toggle paywall visibility
    @Environment(\.paywallToggleAction) var paywallToggleAction

    // Optional: use environment key .hasProSubscription for active customer checks
    @Environment(\.hasProSubscription) private var hasProSubscription

    var body: some View {
        VStack {
            // Toggle the paywall
            Button(action: { paywallToggleAction?() }) {
                Text("Subscribe")
            }

            // Check if the current user is a paying customer
            if hasProSubscription {
                Text("This is only for subscribers visible")
            }
        }
        .awesomePaywall(with: PaywallConfiguration(
                productIDs: ["YourAppPro.Annual", "YourAppPro.Weekly"],
                privacyUrl: URL(string: "https://yourapp.com/privacy")!,
                termsOfServiceUrl: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        ) {
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
}

#Preview {
    ContentView()
        .environmentObject(PaywallStore())
}
