//
//  WithBackgroundColor.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 11.10.25.
//

import SwiftUI

// Use background color full or as gradient
struct WithBackgroundColor<Content: View>: View {
    let color: Color
    var asGradient: Bool = false
    var gradientStart: UnitPoint = .top
    var gradientStop: UnitPoint = .bottom
    @ViewBuilder let content: () -> Content

    init(color: Color, asGradient: Bool = false, gradientStart: UnitPoint = .top, gradientStop: UnitPoint = .bottom, content: @escaping () -> Content) {
        self.color = color
        self.content = content
        self.asGradient = asGradient
        self.gradientStart = gradientStart
        self.gradientStop = gradientStop
    }

    var body: some View {
        if self.asGradient {
            self.content()
                .background(.linearGradient(self.color.gradient, startPoint: self.gradientStart, endPoint: self.gradientStop))
        } else {
            ZStack {
                self.color

                self.content()
            }
        }
    }
}
