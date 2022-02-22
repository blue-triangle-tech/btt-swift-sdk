//
//  URLSession+NetworkCapture.swift
//
//  Created by Mathew Gacy on 2/22/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

// MARK: - Adding Data Tasks to a Session
public extension URLSession {
    @discardableResult
    @inlinable
    func btDataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        let timer = BlueTriangle.startRequestTimer()
        return dataTask(with: url) { data, response, error in
            if var timer = timer {
                timer.end()
                BlueTriangle.captureRequest(timer: timer, data: data, response: response)
            }

            completionHandler(data, response, error)
        }
    }
}
