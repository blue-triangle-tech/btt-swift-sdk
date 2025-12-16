//
//  Session.swift
//
//  Created by Mathew Gacy on 10/12/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct Session: Equatable, @unchecked Sendable {
    let wcd = 1
    let eventType = 9
    let navigationType = 9
    let osInfo = Device.current.os
    let appVersion = Device.current.bvzn

    /// Blue Triangle Technologies-assigned site ID.
    var siteID: String

    /// Global User ID.
    var globalUserID: Identifier

    /// Session ID.
    var sessionID: Identifier

    /// Boolean value indicating whether user is a returning visitor.
    var isReturningVisitor: Bool

    /// A/B testing identifier.
    var abTestID: String

    /// Legacy campaign name.
    var campaign: String?

    /// Campaign medium.
    var campaignMedium: String

    /// Campaign name.
    var campaignName: String

    /// Campaign source.
    var campaignSource: String

    /// Data center.
    var dataCenter: String

    /// Traffic segment.
    var trafficSegmentName: String

    /// Custom metrics.
    var metrics: [String: AnyCodable]?
}

extension Session {
    
    func customVarriables(logger: Logging, encoder: JSONEncoder = .init()) -> String? {
        var customMetrics: String? = nil
        if let metrics = self.metrics {
            do {
                let metricsData = try encoder.encode(metrics)
                let base64MetricsData = metricsData.base64EncodedData()
                if base64MetricsData.count > Constants.metricsSizeLimit {
                    let bcf = ByteCountFormatter()
                    bcf.includesActualByteCount = true

                    func formatted(_ count: Int) -> String {
                        bcf.string(fromByteCount: Int64(count))
                    }

                    logger.log("Custom metrics encoded size of \(formatted(base64MetricsData.count)) exceeds limit of \(formatted(Constants.metricsSizeLimit)); dropping from timer request.")
                } else {
                    customMetrics = String(decoding: metricsData, as: UTF8.self)
                    if customMetrics?.count ?? 0 > Constants.metricsCharacterLimit {
                        logger.log("Custom metrics length is \(customMetrics?.count ?? 0) characters; exceeding \(Constants.metricsCharacterLimit) results in data loss.")
                    }
                }
            } catch {
                logger.log("Custom metrics encoding failed: \(error.localizedDescription)")
            }
        }
        
       return customMetrics
    }
}
