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
    typealias Parameters = [String: String]
    typealias Headers = [String: String]

    let method: HTTPMethod

    let url: URL

    let parameters: Parameters?

    let headers: Headers?

    let body: Data?

    init(method: HTTPMethod, url: URL, parameters: Parameters? = nil, headers: Headers? = nil, body: Data? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }

    func asURLRequest() throws -> URLRequest {
        var urlRequest: URLRequest
        if let parameters = parameters, !parameters.isEmpty,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = parameters.map { URLQueryItem(name: $0.0, value: $0.1) }
            urlRequest = URLRequest(url: components.url!)
        } else {
            urlRequest = URLRequest(url: url)
        }

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
        parameters: Parameters? = nil,
        headers: Headers? = nil,
        model: T,
        encode: (T) throws -> Data = { try JSONEncoder().encode($0).base64EncodedData() }
    ) throws {
        let body = try encode(model)
        self.init(method: method, url: url, parameters: parameters, headers: headers, body: body)
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
