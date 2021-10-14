//
//  Request.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}

struct Request: URLRequestConvertible {
    typealias Headers = [String: String]

    let method: HTTPMethod

    let url: URL

    let headers: Headers?

    let body: Data?

    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        urlRequest.allHTTPHeaderFields = headers

        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        urlRequest.httpBody = body

        return urlRequest
    }
}

extension Request {
    init<T: Encodable>(
        method: HTTPMethod = .post,
        url: URL,
        headers: Headers? = nil,
        model: T,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        let body = try encoder.encode(model)
        self.init(method: method, url: url, headers: headers, body: body)
    }
}

// MARK: - Supporting Types
extension Request {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
}

// MARK: - Equatable
extension Request: Equatable {
    public static func == (lhs: Request, rhs: Request) -> Bool {
         lhs.method == rhs.method
            && lhs.url == rhs.url
            && lhs.headers == rhs.headers
            && lhs.body == rhs.body
    }
}

// MARK: - CustomStringConvertible
extension Request: CustomStringConvertible {
    public var description: String {
         "\(method) \(url.absoluteString) \(body != nil ? (String(data: body!, encoding: .utf8) ?? "") : "")"
    }
}
