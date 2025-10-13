//
//  DefaultPaywallTemplate.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 12.10.25.
//

import SwiftUI
import StoreKit

public struct PaywallDefaultTemplate: View {
    @EnvironmentObject private var store: PaywallStore

    @Environment(\.paywallRestoreAction) private var restoreAction
    @Environment(\.paywallLegalSheetAction) private var legalSheetAction
    @Environment(\.paywallPurchaseAction) private var purchaseAction
    @Environment(\.paywallToggleAction) private var toggleAction

    let title: LocalizedStringKey
    let features: [PaywallDefaultFeature]

    public var body: some View {
        WithBackgroundColor(color: Color.white, asGradient: true, gradientStart: .top, gradientStop: .bottom) {
            VStack {
                PaywallDefaultCloseButton()

                Spacer()

                HStack {
                    Spacer()
                    TitleView(title: title)
                    Spacer()
                }

                VStack(alignment: .leading) {
                    ForEach(features, id: \.id) { feature in
                        FeatureRow(systemImageName: feature.systemImageName, text: feature.title)
                    }
                }

                Spacer()

                PaywallDefaultProductList()
                PaywallDefaultPurchaseButton()
                PaywallDefaultLegalButtonStack()
            }
        }
        .task {
            await store.select(by: .yearly)
        }
    }

    // Title View
    struct TitleView: View {
        let title: LocalizedStringKey

        var body: some View {
            ZStack {
                Text(title)
                    .font(.system(size: 40))
                    .bold()

                Text("Pro")
                    .foregroundStyle(Color.white)
                    .font(.title.bold())
                    .padding(6)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .foregroundStyle(Color.red)
                    }
                    .rotationEffect(.degrees(-10))
                    .padding(.top, 70)

            }
        }
    }

    /// Feature Row
    struct FeatureRow: View {
        let systemImageName: String
        let text: LocalizedStringKey

        var body: some View {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .overlay {
                        Image(systemName: systemImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20, alignment: .center)
                            .clipped()
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white)
                            .padding(3)
                    }
                    .frame(width: 30, height: 30)

                Text(text)
            }
            .font(.system(size: 16, weight: .medium))
        }
    }
}

#Preview {
    @Previewable @StateObject var store = PaywallStore()
    PaywallDefaultTemplate(
        title: "Your Awesome App",
        features: [
            .init(systemImageName: "list.star", title: "Unlimited Features"),
            .init(systemImageName: "widget.large", title: "Become the X-Wing Copilot"),
            .init(systemImageName: "lock.square.stack", title: "Remove Anoying Paywalls")
        ]
    )
        .environmentObject(store)
        .task {
            await store.configure(productIDs: ["YourAppPro.Weekly", "YourAppPro.Annual"])
        }
}

