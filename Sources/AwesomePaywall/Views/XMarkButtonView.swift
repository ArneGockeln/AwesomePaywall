//
//  XMarkButtonView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI

struct XMarkButtonView: View {
        var body: some View {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)
                .padding(.all, 5)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .accessibilityLabel(Text("Close"))
                .accessibilityHint(Text("Tap to close the sheet"))
                .accessibilityAddTraits(.isButton)
                .accessibilityRemoveTraits(.isImage)
        }
    }
