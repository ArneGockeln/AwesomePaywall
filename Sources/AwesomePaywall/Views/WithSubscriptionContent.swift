//
//  WithSubscriptionContent.swift
//  Elated
//
//  Created by Arne Gockeln on 09.10.25.
//

import SwiftUI

public struct WithSubscriptionContent<SubscribedContent: View, UnsubscribedContent: View>: View {
    @Environment(\.hasProSubscription) var hasProSubscription

    @ViewBuilder let subscribed: () -> SubscribedContent
    @ViewBuilder let unsubscribed: () -> UnsubscribedContent

    public init(subscribed: @escaping () -> SubscribedContent, unsubscribed: @escaping () -> UnsubscribedContent) {
        self.subscribed = subscribed
        self.unsubscribed = unsubscribed
    }

    public var body: some View {
        if hasProSubscription {
            subscribed()
        } else {
            unsubscribed()
        }
    }
}
