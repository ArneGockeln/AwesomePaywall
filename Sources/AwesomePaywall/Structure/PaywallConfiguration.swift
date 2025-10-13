//
//  PaywallConfiguration.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 01.10.25.
//

import SwiftUI

public struct PaywallConfiguration {
    let productIDs: [String]
    let privacyUrl: URL
    let termsOfServiceUrl: URL

    public init(
        productIDs: [String],
        privacyUrl: URL,
        termsOfServiceUrl: URL,
    ) {
        self.productIDs = productIDs
        self.privacyUrl = privacyUrl
        self.termsOfServiceUrl = termsOfServiceUrl
    }
}
