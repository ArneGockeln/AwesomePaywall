//
//  RestoreButtonView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

// MARK: - Restore Button
extension PaywallView {
    struct RestoreButtonView: View {
        var onButtonPressed: () -> Void

        var body: some View {
            Button("Restore") {
                onButtonPressed()
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .foregroundStyle(Color.black.opacity(0.5))
            .font(.footnote)
        }
    }
}
