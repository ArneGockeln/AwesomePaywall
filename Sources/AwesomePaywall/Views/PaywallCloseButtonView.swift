//
//  PaywallCloseButtonView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

struct PaywallCloseButtonView: View {
    @Binding var showCloseButton: Bool
    @Binding var isPresented: Bool
    @Binding var progress: CGFloat

    var body: some View {
        HStack {
            Spacer()

            if !showCloseButton {
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .opacity(0.1 + 0.1 * self.progress)
                    .rotationEffect(Angle(degrees: -90))
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "multiply")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, alignment: .center)
                    .clipped()
                    .onTapGesture {
                        isPresented = false
                    }
                    .opacity(0.2)
            }
        }
        .padding(.top, 60)
        .padding(.trailing, 30)
    }
}

// MARK: - Paywall Close Button View
extension PaywallView {

}
