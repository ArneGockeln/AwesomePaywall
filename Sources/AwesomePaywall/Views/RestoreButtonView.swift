//
//  RestoreButtonView.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 21.09.25.
//

import SwiftUI

// MARK: - Restore Button
extension PaywallView {
    struct RestoreButtonView: View {
        @State private var showNoneRestoreAlert: Bool = false
        @EnvironmentObject private var storeModel: StoreManager
        @Binding var isPurchasing: Bool

        var body: some View {
            Button("Restore") {
                // storeModel try to restore
                restorePurchase()
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .foregroundStyle(Color.black.opacity(0.5))
            .font(.footnote)
            .alert("Restore failed", isPresented: $showNoneRestoreAlert) {
                Button("OK", role: .destructive) {
                    self.isPurchasing = false
                }
            } message: {
                Text("No purchases restored.")
            }
        }

        /// Restore previous purchases
        private func restorePurchase() {
            Task {
                self.isPurchasing = true
                await self.storeModel.restorePurchases()
                self.isPurchasing = false

                if !self.storeModel.hasPurchased {
                    self.showNoneRestoreAlert = true
                }
            }
        }
    }
}
