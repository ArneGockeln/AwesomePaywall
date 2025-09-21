//
//  AwesomePaywallViewModifier.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

public struct AwesomePaywallViewModifier<V: View>: ViewModifier {
    @Binding var isPresented: Bool
    var backgroundColor: Color
    var highlightColor: Color
    let hero: () -> V

    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                PaywallView(isPresented: $isPresented, backgroundColor: backgroundColor, highlightColor: highlightColor, heroView: hero)
            }
    }
}
