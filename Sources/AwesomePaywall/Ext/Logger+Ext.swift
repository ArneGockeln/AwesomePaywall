//
//  Logger+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import OSLog

extension Logger {
    /// Logs are related the paywall system only
    static let app = Logger(subsystem: "com.arnesoftware.AwesomePaywall", category: "paywall")
}
