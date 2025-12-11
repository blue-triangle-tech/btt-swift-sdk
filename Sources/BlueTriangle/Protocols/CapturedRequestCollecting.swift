//
//  CapturedRequestCollecting.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol CapturedRequestCollecting: Actor {
    func start(page: Page, startTime: TimeInterval, isGroupTimer: Bool)
    func update(pageName : String, startTime: Millisecond)
    func collect(timer: InternalTimer, response: CustomResponse) async
    func collect(metrics: URLSessionTaskMetrics, error : Error?) async
    func collect(timer: InternalTimer, response: URLResponse?) async
    func collect(timer: InternalTimer, request : URLRequest, error: Error?) async
}
