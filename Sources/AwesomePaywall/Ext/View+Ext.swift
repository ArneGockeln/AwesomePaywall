//
//  View+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

public extension View {
    func awesomePaywall(isPresented: Binding<Bool>, backgroundColor: Color = Color.orange, highlightColor: Color = Color.red, @ViewBuilder hero: @escaping () -> some View) -> some View {
        modifier(AwesomePaywallViewModifier(isPresented: isPresented, backgroundColor: backgroundColor, highlightColor: highlightColor, hero: hero))
    }
}
