//
//  CapturedRequestCollecting.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol CapturedRequestCollecting {
    func start(page: Page, startTime: TimeInterval) async
    func collect(timer: InternalTimer, response: URLResponse?) async
}
