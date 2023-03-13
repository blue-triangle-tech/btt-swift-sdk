//
//  TimerRequestBuilder.swift
//
//  Created by Mathew Gacy on 6/15/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct TimerRequestBuilder {
    let builder: (Session, BTTimer, PurchaseConfirmation?) throws -> Request

    static func live(logger: Logging) -> Self {
        let encoder = JSONEncoder()

        return .init { session, timer, purchase in
            var customMetrics: String? = nil
            if let metrics = session.metrics {
                do {
                    let metricsString = String(decoding: try encoder.encode(metrics), as: UTF8.self)

                    let base64MetricsData = Data(metricsString.utf8).base64EncodedData()
                    if base64MetricsData.count > Constants.metricsSizeLimit {
                        let bcf = ByteCountFormatter()
                        bcf.includesActualByteCount = true

                        func formatted(_ count: Int) -> String {
                            bcf.string(fromByteCount: Int64(count))
                        }

                        logger.log("Custom metrics encoded size of \(formatted(base64MetricsData.count)) exceeds limit of \(formatted(Constants.metricsSizeLimit)); dropping from timer request.")
                    } else {
                        if metricsString.count > Constants.metricsCharacterLimit {
                            logger.log("Custom metrics length is \(metricsString.count) characters; exceeding \(Constants.metricsCharacterLimit) results in data loss.")
                        }

                        customMetrics = metricsString
                    }
                } catch {
                    logger.log("Custom metrics encoding failed: \(error.localizedDescription)")
                }
            }

            let model = TimerRequest(session: session,
                                     page: timer.page,
                                     timer: timer.pageTimeInterval,
                                     customMetrics: customMetrics,
                                     purchaseConfirmation: purchase,
                                     performanceReport: timer.performanceReport)

            return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           model: model)
        }
    }
}
