//
//  Log.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 26.09.25.
//

import OSLog

@MainActor
final class Log {
     static let shared = Log()

    private init() {

    }

    public func info(_ text: String) {
        #if DEBUG
        Logger.app.info("\(text)")
        #endif
    }

    public func error(_ text: String) {
        #if DEBUG
        Logger.app.error("\(text)")
        #endif
    }
}
