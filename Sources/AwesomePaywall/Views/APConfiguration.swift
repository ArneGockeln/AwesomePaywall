//
//  APConfiguration.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI

public struct APConfiguration {
    let productIDs: [String]
    let privacyUrl: URL
    let termsOfServiceUrl: URL
    let backgroundColor: Color
    let foregroundColor: Color

    public init(productIDs: [String], privacyUrl: URL, termsOfServiceUrl: URL, backgroundColor: Color, foregroundColor: Color) {
        self.productIDs = productIDs
        self.privacyUrl = privacyUrl
        self.termsOfServiceUrl = termsOfServiceUrl
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
}
