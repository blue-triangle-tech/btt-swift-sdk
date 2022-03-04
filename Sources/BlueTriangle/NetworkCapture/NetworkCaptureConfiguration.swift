//
//  NetworkCaptureConfiguration.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// Configuration for network request capture.
struct NetworkCaptureConfiguration {
    /// Maximum number of times to send batched requests for a given `Page`.
    public var spanCount: Int
    /// Duration of time to wait before sending the first batch of captured requests for the current
    /// `Page`.
    public var initialSpanDuration: TimeInterval
    /// Duration of time to wait before sending the second and any subsequent batches of captured
    /// requests for the current `Page`.
    public var subsequentSpanDuration: TimeInterval
}

extension NetworkCaptureConfiguration {
    static let standard: Self = .init(spanCount: 2, initialSpanDuration: 20, subsequentSpanDuration: 10)
}
