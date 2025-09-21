//
//  TermsOfUseButton.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

extension PaywallView {
    struct TermsOfUseButton: View {
        let privacyUrl: String?
        let termsOfUseUrl: String?

        @State private var showTermsActionSheet: Bool = false

        var body: some View {
            Button("Terms of Use & Privacy Policy") {
                showTermsActionSheet = true
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .foregroundStyle(Color.black.opacity(0.5))
            .font(.footnote)
            .confirmationDialog(Text("View Terms & Conditions"), isPresented: $showTermsActionSheet) {
                if let termsOfUseUrl = self.termsOfUseUrl {
                    Button("Terms of Use") {
                        if let url = URL(string: termsOfUseUrl) {
                            UIApplication.shared.open(url)
                        }
                    }
                }

                if let privacyUrl = self.privacyUrl {
                    Button("Privacy Policy") {
                        if let url = URL(string: privacyUrl) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

        }
    }
}
