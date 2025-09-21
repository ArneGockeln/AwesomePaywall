//
//  Product+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import StoreKit

extension Product {
    func hasTrial() -> Bool {
        return self.subscription?.subscriptionPeriod == .weekly
    }
}
