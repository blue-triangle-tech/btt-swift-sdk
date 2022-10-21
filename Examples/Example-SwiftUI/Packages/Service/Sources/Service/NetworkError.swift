//
//  NetworkError.swift
//
//  Created by Mathew Gacy on 10/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public enum NetworkError: Error {
    /// Not a valid request.
    case malformedRequest
    /// Capture any underlying Error from the URLSession API.
    case network(error: Error)
    /// No data returned from server.
    case noData
    /// The server response was in an unexpected format.
    case invalidResponse(URLResponse?)
    /// There was a client error: 400-499.
    case clientError(HTTPURLResponse)
    /// There was a server error.
    case serverError(HTTPURLResponse)
    /// There was an error decoding the data.
    case decoding(error: Error)
    /// Unknown error.
    case unknown(message: String)

    /// Returns an appropriate network client error for the passed error.
    /// - Parameter error: A general error.
    /// - Returns: The network client error case corresponding to `error`.
    public static func wrap(_ error: Error) -> NetworkError {
        switch error {
        case let error as NetworkError:
            return error
        case is DecodingError:
            return .decoding(error: error)
        case is URLError:
            return .network(error: error)
        default:
            return .unknown(message: error.localizedDescription)
        }
    }
}
