//
//  URLRequest+Utils.swift
//
//  Created by Mathew Gacy on 10/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

private extension URLRequest {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    static func build(
        _ method: HTTPMethod,
        url: URL,
        queryItems: [URLQueryItem]? = nil,
        headerFields: [String: String]? = nil
    ) -> Self {
        var request: URLRequest
        if let queryItems = queryItems, !queryItems.isEmpty,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = queryItems
            request = URLRequest(url: components.url!)
        } else {
            request = URLRequest(url: url)
        }

        request.httpMethod = method.rawValue

        if let headerFields {
            request.allHTTPHeaderFields = headerFields
        }

        return request
    }
}

extension URLRequest {
    static func get(_ url: URL, queryItems: [URLQueryItem]? = nil, headers: [String: String]? = nil) -> Self {
        build(.get, url: url, queryItems: queryItems, headerFields: headers)
    }

    static func post<T: Encodable>(_ url: URL, body: T, headers: [String: String]? = nil) throws -> Self {
        var request = build(.post, url: url, headerFields: headers)

        let data = try JSONEncoder().encode(body)
        request.httpBody = data

        return request
    }
}
