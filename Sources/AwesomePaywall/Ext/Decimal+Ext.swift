//
//  Decimal+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import Foundation

extension Decimal {
    mutating func round(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) {
        var localCopy = self
        NSDecimalRound(&self, &localCopy, scale, roundingMode)
    }

    func rounded(_ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var localCopy = self
        NSDecimalRound(&result, &localCopy, scale, roundingMode)
        return result
    }

    func toDouble() -> Double {
        return (self as NSDecimalNumber).doubleValue
    }

    func toInt() -> Int {
        return (self as NSDecimalNumber).intValue
    }
}
