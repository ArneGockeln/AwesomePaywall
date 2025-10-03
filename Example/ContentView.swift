//
//  ContentView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI
import AwesomePaywall

struct ContentView: View {
    // Get access to the APStore
    @EnvironmentObject private var storeModel: APStore

    var body: some View {
        VStack {
            // Toggle the paywall
            Button(action: { storeModel.isPaywallPresented.toggle() }) {
                Text("Subscribe")
            }

            // Check if the current user is a paying customer
            if storeModel.hasProSubscription {
                Text("This is only for subscribers visible")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APStore())
}
