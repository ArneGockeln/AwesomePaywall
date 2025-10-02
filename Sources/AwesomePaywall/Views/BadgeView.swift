//
//  BadgeView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI

struct BadgeView: View {
        let text: LocalizedStringKey
        let backgroundColor: Color

        var body: some View {
            Text(text)
                .foregroundStyle(Color.black)
                .font(.caption.bold())
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(backgroundColor)
                }
        }
    }
