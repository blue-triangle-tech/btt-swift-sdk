//
//  URLSession+Publisher.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

enum NetworkError: Error {
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

struct HTTPResponse<T> {
    let value: T
    let response: HTTPURLResponse

    func map<U>(_ transform: (T) -> U) -> HTTPResponse<U> {
        HTTPResponse<U>(value: transform(value), response: response)
    }
}

extension HTTPResponse {
    func validateStatus() throws {
        switch response.statusCode {
        // Success
        case (200..<300): return
        // Client Error
        case (400..<500): throw NetworkError.clientError(response)
        // Server Error
        case (500..<600): throw NetworkError.serverError(response)
        default: throw NetworkError.unknown(message: "Unrecognized status code: \(response.statusCode)")
        }
    }
}

 extension URLSession {
     func dataTaskPublisher(for request: Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError> {
         dataTaskPublisher(for: request.asURLRequest())
             .tryMap { data, response -> HTTPResponse<Data> in
                 guard let httpResponse = response as? HTTPURLResponse else {
                     throw NetworkError.invalidResponse(response)
                 }
                 return HTTPResponse(value: data, response: httpResponse)
             }
             .mapError { NetworkError.wrap($0) }
             .eraseToAnyPublisher()
     }
 }
