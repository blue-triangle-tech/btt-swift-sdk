//
//  URLSession+NetworkCapture.swift
//
//  Created by Mathew Gacy on 2/22/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

// MARK: - Adding Data Tasks to a Session
public extension URLSession {
    /// Creates a task that retrieves the contents of the specified URL, then calls a handler upon completion.
    /// - Parameters:
    ///   - url: The URL to be retrieved.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session data task.
    @discardableResult
    @inlinable
    func btDataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        btDataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }

    /// Creates a task that retrieves the contents of a URL based on the specified URL request object, and calls a handler upon completion.
    /// - Parameters:
    ///   - request: A URL request object that provides the URL, cache policy, request type, body data or body stream, and so on.
    ///   - completionHandler: The completion handler to call when the load request is complete. This handler is executed on the delegate queue.
    /// - Returns: The new session data task.
    @discardableResult
    @inlinable
    func btDataTask(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let timer = BlueTriangle.startRequestTimer()
        return dataTask(with: request) { data, response, error in
            if var timer = timer {
                timer.end()
                BlueTriangle.captureRequest(timer: timer, data: data, response: response)
            }

            completionHandler(data, response, error)
        }
    }
}

// MARK: - Performing Asynchronous Transfers
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public extension URLSession {
    /// Downloads the contents of a URL based on the specified URL request and delivers the data asynchronously.
    /// - Parameters:
    ///   - request: A URL request object that provides request-specific information such as the URL, cache policy, request type, and body data or body stream.
    ///   - delegate: A delegate that receives life cycle and authentication challenge callbacks as the transfer progresses.
    /// - Returns: An asynchronously-delivered tuple that contains the URL contents as a `Data` instance, and a `URLResponse`.
    @inlinable
    func btData(
        for request: URLRequest,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        let timer = BlueTriangle.startRequestTimer()
        let asyncTuple = try await data(for: request, delegate: delegate)
        if var timer = timer {
            timer.end()
            BlueTriangle.captureRequest(timer: timer, tuple: asyncTuple)
        }
        return asyncTuple
    }

    /// Retrieves the contents of a URL and delivers the data asynchronously.
    /// - Parameters:
    ///   - url: The URL to retrieve.
    ///   - delegate: A delegate that receives life cycle and authentication challenge callbacks as the transfer progresses.
    /// - Returns: An asynchronously-delivered tuple that contains the URL contents as a `Data` instance, and a `URLResponse`.
    @inlinable
    func btData(
        from url: URL,
        delegate: URLSessionTaskDelegate? = nil
    ) async throws -> (Data, URLResponse) {
        try await btData(for: URLRequest(url: url), delegate: delegate)
    }
}
