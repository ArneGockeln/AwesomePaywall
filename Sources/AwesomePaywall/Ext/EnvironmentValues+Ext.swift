//
//  EnvironmentValues+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 08.10.25.
//

import SwiftUI
import StoreKit

public struct PaywallHasProEnvKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

public struct PaywallToggleActionEnvKey: EnvironmentKey {
    public static var defaultValue: (() -> Void)? { nil }
}

public struct PaywallRestoreActionEnvKey: EnvironmentKey {
    public static var defaultValue: (() -> Void)? { nil }
}

public struct PaywallLegalSheetActionEnvKey: EnvironmentKey {
    public static var defaultValue: ((PresentedSheet) -> Void)? { nil }
}

public struct PaywallPurchaseActionEnvKey: EnvironmentKey {
    public static var defaultValue: ((Product) -> Void)? { nil }
}

public extension EnvironmentValues {
    var hasProSubscription: Bool {
        get { self[PaywallHasProEnvKey.self] }
        set { self[PaywallHasProEnvKey.self] = newValue }
    }

    var paywallToggleAction: (() -> Void)? {
        get { self[PaywallToggleActionEnvKey.self] }
        set { self[PaywallToggleActionEnvKey.self] = newValue }
    }

    var paywallRestoreAction: (() -> Void)? {
        get { self[PaywallRestoreActionEnvKey.self] }
        set { self[PaywallRestoreActionEnvKey.self] = newValue }
    }

    var paywallLegalSheetAction: ((PresentedSheet) -> Void)? {
        get { self[PaywallLegalSheetActionEnvKey.self] }
        set { self[PaywallLegalSheetActionEnvKey.self] = newValue }
    }

    var paywallPurchaseAction: ((Product) -> Void)? {
        get { self[PaywallPurchaseActionEnvKey.self] }
        set { self[PaywallPurchaseActionEnvKey.self] = newValue }
    }
}
