//
//  NetworkCaptureConfiguration.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct NetworkCaptureConfiguration {
    public var spanCount: Int
    public var initialSpanDuration: TimeInterval
    public var subsequentSpanDuration: TimeInterval
}

extension NetworkCaptureConfiguration {
    static let standard: Self = .init(spanCount: 2, initialSpanDuration: 20, subsequentSpanDuration: 10)
}
