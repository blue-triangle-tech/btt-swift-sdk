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
        accept: ContentType? = nil,
        contentType: ContentType? = nil,
        body: Data? = nil,
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

        if let accept {
            request.setValue(accept.rawValue, forHTTPHeaderField: "Accept")
        }

        if let contentType {
            request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }

        if let headerFields {
            headerFields.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }

        request.httpMethod = method.rawValue

        if let headerFields {
            request.allHTTPHeaderFields = headerFields
        }

        if let body {
            request.httpBody = body
        }

        return request
    }
}

extension URLRequest {
    enum ContentType: String {
        case json = "application/json"
        case urlencoded = "application/x-www-form-urlencoded"
    }

    static func delete(
        _ url: URL,
        accept: ContentType = .json,
        headers: [String: String]? = nil
    ) -> Self {
        build(
            .delete,
            url: url,
            accept: accept,
            headerFields: headers)
    }

    static func get(
        _ url: URL,
        accept: ContentType = .json,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String]? = nil
    ) -> Self {
        build(
            .get,
            url: url,
            accept: accept,
            queryItems: queryItems,
            headerFields: headers)
    }

    static func patch<T: Encodable>(
        _ url: URL,
        accept: ContentType = .json,
        contentType: ContentType? = .json,
        body: T,
        headers: [String: String]? = nil
    ) throws -> Self {
        build(
            .patch,
            url: url,
            accept: accept,
            contentType: contentType,
            body: try JSONEncoder().encode(body),
            headerFields: headers)
    }

    static func post<T: Encodable>(
        _ url: URL,
        accept: ContentType = .json,
        contentType: ContentType? = .json,
        body: T,
        headers: [String: String]? = nil
    ) throws -> Self {
        build(
            .post,
            url: url,
            accept: accept,
            contentType: contentType,
            body: try JSONEncoder().encode(body),
            headerFields: headers)
    }
}
