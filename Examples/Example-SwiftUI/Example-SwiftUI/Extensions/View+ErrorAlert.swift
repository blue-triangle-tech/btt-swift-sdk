//
//  View+ErrorAlert.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

private struct LocalizedErrorWrapper: LocalizedError {
    let underlyingError: Error

    var errorDescription: String? {
        "Oops"
    }

    var recoverySuggestion: String? {
        "There was an error"
    }

    init(_ error: Error) {
        self.underlyingError = error
    }
}

private struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError

    var errorDescription: String? {
        underlyingError.errorDescription
    }

    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error.flatMap(Self.wrap) else {
            return nil
        }
        self.underlyingError = localizedError
    }

    static func wrap(error: Error) -> LocalizedError {
        error as? LocalizedError ?? LocalizedErrorWrapper(error)
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
}
