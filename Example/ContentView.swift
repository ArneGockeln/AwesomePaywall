//
//  ContentView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI
import AwesomePaywall

struct ContentView: View {
    @State private var isPaywallPresented: Bool = false
    @EnvironmentObject private var storeManager: StoreManager

    var body: some View {
        VStack {
            // Toggle the paywall
            Button(action: { isPaywallPresented.toggle() }) {
                Text("Subscribe")
            }

            // Check if the current user is a paying customer
            if storeManager.isPayingCustomer() {
                Text("This is only for subscribers visible")
            }
        }
        // Add Paywall fullscreen cover
        .awesomePaywall(isPresented: $isPaywallPresented) {
            // This represents the Title and main Features
            PaywallHeroView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreManager.shared)
}
