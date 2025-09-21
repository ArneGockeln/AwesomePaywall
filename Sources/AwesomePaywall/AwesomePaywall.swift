// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

struct AwesomePaywallViewModifier: ViewModifier {
    let backgroundColor: Color
    let highlightColor: Color

    @State private var isPaywallPresented: Bool = false
    @StateObject private var storeManager: StoreManager = .shared

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPaywallPresented) {
                PaywallView(backgroundColor: backgroundColor, highlightColor: highlightColor, isPresented: $isPaywallPresented)
            }
            .environmentObject(storeManager)
            .task {
                await storeManager.configure()
            }
    }
}

extension View {
    func awesomePaywall(backgroundColor: Color = Color.orange, highlightColor: Color = Color.red) -> some View {
        modifier(AwesomePaywallViewModifier(backgroundColor: backgroundColor, highlightColor: highlightColor))
    }
}
