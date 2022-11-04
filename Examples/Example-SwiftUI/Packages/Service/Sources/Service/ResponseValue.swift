//
//  ResponseValue.swift
//
//  Created by Mathew Gacy on 10/2/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct ResponseValue {
    public let data: Data
    public let httpResponse: HTTPURLResponse

    public var statusCode: Int {
        httpResponse.statusCode
    }

    public init(data: Data, httpResponse: HTTPURLResponse) {
        self.data = data
        self.httpResponse = httpResponse
    }
}

public extension ResponseValue {
    init(_ tuple: (Data, URLResponse)) throws {
        guard let httpResponse = tuple.1 as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(tuple.1)
        }
        self.data = tuple.0
        self.httpResponse = httpResponse
    }
}

public extension ResponseValue {
    @discardableResult
    func validate() throws -> Self {
        switch statusCode {
        // Informational
        case (100..<200): return self
        // Success
        case (200..<300): return self
        // Redirection
        case (300..<400): return self
        // Client Error
        case (400..<500): throw NetworkError.clientError(httpResponse)
        // Server Error
        case (500..<600): throw NetworkError.serverError(httpResponse)
        default: throw NetworkError.unknown(message: "Unrecognized status code: \(statusCode)")
        }
    }

    func decode<T: Decodable>(with decoder: JSONDecoder = .init()) throws -> T {
        try decoder.decode(T.self, from: data)
    }
}
