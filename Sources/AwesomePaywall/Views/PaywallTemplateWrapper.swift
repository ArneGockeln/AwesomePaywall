//
//  PaywallTemplateWrapper.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 12.10.25.
//

import SwiftUI
import StoreKit

struct PaywallTemplateWrapper<Content: View>: View {
    let config: PaywallConfiguration
    let template: () -> Content

    @EnvironmentObject private var store: PaywallStore
    @State private var isSheetPresented: PresentedSheet?
    
    var body: some View {
        template()
            .environment(\.paywallLegalSheetAction) { sheet in
                Task {
                    self.isSheetPresented = sheet
                }
            }
            .ignoresSafeArea()
            // show legal terms of service or privacy policy url in webview
            .sheet(item: $isSheetPresented) { sheet in
                VStack {
                    HStack {
                        Spacer()

                        Button(action: { isSheetPresented = nil }) {
                            XMarkButtonView()
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }

                    AwesomeWebView(url: sheet == .privacy ? config.privacyUrl : config.termsOfServiceUrl)
                }
            }
    }
}
