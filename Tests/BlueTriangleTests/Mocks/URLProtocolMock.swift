//
//  URLProtocolMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest

final class URLProtocolMock: URLProtocol {
    static var responseQueue: DispatchQueue = .global()
    static var responseDelay: TimeInterval? = 0.3
    static var responseProvider: (URL) throws -> (Data, HTTPURLResponse) = { url in
        (Data(), Mock.makeHTTPResponse(url: url))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let delay = Self.responseDelay {
            guard client != nil else { return }
            Self.responseQueue.asyncAfter(deadline: .now() + delay) {
                self.respond()
            }
        } else {
            respond()
        }
    }

    override func stopLoading() { }

    private func respond() {
        guard let client = client else { return }
        do {
            let url = try XCTUnwrap(request.url)
            let response = try Self.responseProvider(url)
            client.urlProtocol(self, didReceive: response.1, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: response.0)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
        client.urlProtocolDidFinishLoading(self)
    }
}

extension URLSessionConfiguration {
    static var mock: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return config
    }
}
