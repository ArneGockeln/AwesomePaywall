//
//  PaywallDefaultLegalButtonList.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 13.10.25.
//

import SwiftUI

public struct PaywallDefaultLegalButtonStack: View {
    @Environment(\.paywallRestoreAction) private var restoreAction
    @Environment(\.paywallLegalSheetAction) private var legalSheetAction

    public init() {
        
    }

    public var body: some View {
        HStack {
            legalButton(text: "Restore Purchase") {
                restoreAction?()
            }

            Text("•")

            legalButton(text: "Terms of Use") {
                legalSheetAction?(.terms)
            }

            Text("•")

            legalButton(text: "Privacy Policy") {
                legalSheetAction?(.privacy)
            }
        }
        .padding([.horizontal, .bottom])
    }

    @ViewBuilder
    private func legalButton(text: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.footnote.bold())
        }
        .buttonStyle(.plain)
    }
}
