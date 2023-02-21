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
        let encodeer = JSONEncoder()

        return .init { session, timer, purchase in
            let request = TimerRequest(session: session,
                                       page: timer.page,
                                       timer: timer.pageTimeInterval,
                                       purchaseConfirmation: purchase,
                                       performanceReport: timer.performanceReport)

            var requestData = try encodeer.encode(request)
            if let metrics = session.metrics {
                do {
                    let metricsData = try encodeer.encode(metrics)

                    let base64MetricsData = metricsData.base64EncodedData()
                    if base64MetricsData.count > Constants.metricsSizeLimit {
                        let bcf = ByteCountFormatter()
                        bcf.includesActualByteCount = true

                        func formatted(_ count: Int) -> String {
                            bcf.string(fromByteCount: Int64(count))
                        }

                        logger.error("Custom metrics encoded size of \(formatted(base64MetricsData.count)) exceeds limit of \(formatted(Constants.metricsSizeLimit)); dropping from timer request.")
                    } else {
                        let metricsString = String(decoding: metricsData, as: UTF8.self)
                        if metricsString.count > Constants.metricsCharacterLimit {
                            logger.error("Custom metrics length is \(metricsString.count) characters; exceeding \(Constants.metricsCharacterLimit) results in data loss.")
                        }

                        try requestData.append(objectData: metricsData, key: Constants.metricsCodingKey)
                    }

                } catch {
                    logger.error("Custom metrics encoding failed: \(error.localizedDescription)")
                }
            }

            return Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           body: requestData)
        }
    }
}
