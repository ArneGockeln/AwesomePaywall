//
//  AppMain.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI
import AwesomePaywall

@main
struct AppMain: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .awesomePaywall(with: APConfiguration(
                        productIDs: ["YourApp.Annual", "YourApp.Weekly"],
                        privacyUrl: URL(string: "https://yourdomain.com/privacy")!,
                        termsOfServiceUrl: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
                        backgroundColor: Color.red,
                        foregroundColor: Color.black
                    )
                ) {
                    PaywallMarketingView()
                }
        }
    }
}
