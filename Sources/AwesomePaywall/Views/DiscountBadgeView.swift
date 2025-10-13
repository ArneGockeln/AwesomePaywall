//
//  DiscountBadgeView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI

struct DiscountBadgeView: View {
        let discount: Int
        let backgroundColor: Color

        var body: some View {
            Text("SAVE \(discount)%")
                .font(.caption.bold())
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundStyle(backgroundColor)
                }
        }
    }
