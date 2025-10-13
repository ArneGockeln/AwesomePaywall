//
//  PaywallDefaultCloseButton.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 13.10.25.
//

import SwiftUI

public struct PaywallDefaultCloseButton: View {
    @Environment(\.paywallToggleAction) private var toggleAction

    public init() {
        
    }

    public var body: some View {
        HStack {
            Spacer()

            Button(action: { toggleAction?() }) {
                XMarkButtonView()
                    .opacity(0.4)
            }
            .padding(.trailing)
        }
        .padding(.trailing, 10)
        .padding(.top, 60)
    }
}
