//
//  NetworkCaptureSessionDelegate.swift
//
//  Created by Mathew Gacy on 11/10/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// A session delegate that supports capturing network requests.
open class NetworkCaptureSessionDelegate: NSObject, URLSessionTaskDelegate {

    /// Tells the delegate that the session finished collecting metrics for the task.
    /// - Parameters:
    ///   - session: The session collecting the metrics.
    ///   - task: The task whose metrics have been collected.
    ///   - metrics: The collected metrics.
    open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
//        print("\(#function): \(metrics)")
        print("\(#function)")
        BlueTriangle.captureRequest(metrics: metrics)
    }
}
