//
//  DecodingError+Description.swift
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension DecodingError.Context {
    var codingPathStringRepresentation: String {
        codingPath
            .map(\.stringValue)
            .joined(separator: ".")
    }
}

public extension DecodingError {
    /// Return a string with a human readable reason for json decoding failure.
    var userDescription: String {
        switch self {
        case .dataCorrupted(let context):
            return context.debugDescription
        case let .keyNotFound(key, context):
            return "The JSON attribute `\(context.codingPathStringRepresentation).\(key.stringValue)` is missing."
        case let .typeMismatch(type, context):
            return "The JSON attribute `\(context.codingPathStringRepresentation)` was not expected type \(type)."
        case let .valueNotFound(_, context):
            return "The JSON attribute `\(context.codingPathStringRepresentation)` is null."
        @unknown default:
            return localizedDescription
        }
    }
}
