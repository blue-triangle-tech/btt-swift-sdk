//
//  PersistenceError.swift
//
//  Created by Mathew Gacy on 7/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

enum PersistenceError: Error {
    case encoding(EncodingError)
    case decoding(DecodingError)
    case file(path: String, error: Error)

    init(underlyingError: Error, path: String = "") {
        switch underlyingError {
        case let error as EncodingError:
            self = .encoding(error)
        case let error as DecodingError:
            self = .decoding(error)
        case let error as PersistenceError:
            self = error
        default:
            self = .file(path: path, error: underlyingError)
        }
    }

    var localizedDescription: String {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .file(path: path, error: error):
            return "Operation on \(path) failed: \(error.localizedDescription)"
        }
    }
}
