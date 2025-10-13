//
//  View+Ext.swift
//  AwesomePaywall
//
//  Created by Arne Gockeln on 12.10.25.
//

import SwiftUI

extension View {
    // https://www.avanderlee.com/swiftui/swiftui-alert-presenting/
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "Ok") -> some View {
        let localizedError = LocalizedAlertError(error: error.wrappedValue)

        return alert(isPresented: .constant(localizedError != nil), error: localizedError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }
    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}
