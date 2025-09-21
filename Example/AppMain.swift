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
    @StateObject private var storeManager: StoreManager = .shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await storeManager.configure(productIdentifiers: [
                        "YourAppNamePro.Annual",
                        "YourAppNamePro.Weekly"
                    ])
                }
        }
        .environmentObject(self.storeManager)
    }
}
