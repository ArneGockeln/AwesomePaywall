//
//  EnvironmentValues+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 08.10.25.
//

import SwiftUI

struct AwesomePaywallProKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    public var hasProSubscription: Bool {
        get { self[AwesomePaywallProKey.self] }
        set { self[AwesomePaywallProKey.self] = newValue }
    }
}
