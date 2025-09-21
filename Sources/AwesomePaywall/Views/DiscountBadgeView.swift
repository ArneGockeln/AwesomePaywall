//
//  DiscountBadgeView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

struct DiscountBadgeView: View {
    let discount: Int

    var body: some View {
        Text("SAVE \(discount)%")
            .foregroundStyle(Color.white)
            .font(.caption.bold())
            .padding(6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(Color.red)
            }
    }
}
