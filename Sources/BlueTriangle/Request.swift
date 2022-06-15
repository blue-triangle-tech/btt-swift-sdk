//
//  Request.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct Request: URLRequestConvertible {
    /// The query items for a request URL.
    typealias Parameters = [String: String]

    /// The HTTP header fields for a request.
    typealias Headers = [String: String]

    /// The HTTP request method.
    let method: HTTPMethod
    /// The URL of the request.
    let url: URL
    /// The query items for the request URL.
    let parameters: Parameters?
    /// The HTTP header fields for a request.
    let headers: Headers?
    /// The data sent as the message body of a request, such as for an HTTP POST request.
    let body: Data?

    /// Creates a request.
    /// - Parameters:
    ///   - method: The HTTP method for the request.
    ///   - url: The URL for the request.
    ///   - parameters: The query items for the request URL.
    ///   - headers: The HTTP header fields for the request.
    ///   - body: The data for the request body.
    init(method: HTTPMethod, url: URL, parameters: Parameters? = nil, headers: Headers? = nil, body: Data? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }

    /// Returns a ``URLRequest`` created from this request.
    /// - Returns: The URL request instance.
    func asURLRequest() -> URLRequest {
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
    /// Creates a request.
    /// - Parameters:
    ///   - method: The HTTP method for the request.
    ///   - url: The URL for the request.
    ///   - parameters: The query items for the request URL.
    ///   - headers: The HTTP header fields for the request.
    ///   - model: The model to be encoded as the body for the request.
    ///   - encode: The closure to encode the model for the request body.
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
    /// The HTTP Method.
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
