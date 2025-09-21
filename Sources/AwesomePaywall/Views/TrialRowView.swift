//
//  TrialRowView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

// MARK: - Trial Row
extension PaywallView {
    struct TrialRowView: View {
        @Binding var isEnabled: Bool
        var highlightColor: Color

        var body: some View {
            HStack {
                Toggle(isOn: $isEnabled) {
                    Text("Free Trial Enabled")
                        .font(.headline.bold())
                }
                .padding(.horizontal)
                .tint(highlightColor)
            }
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
        }
    }
}
