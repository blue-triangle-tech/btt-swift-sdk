//
//  TimerRequestBuilder.swift
//
//  Created by Mathew Gacy on 6/15/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct TimerRequestBuilder {
    let builder: (Session, BTTimer, PurchaseConfirmation?) throws -> Request

    static func live(logger: Logging, encoder: JSONEncoder = .init()) -> Self {
        .init { session, timer, purchase in
            let customMetrics = session.customVarriables(logger: logger, encoder: encoder)
            let body = try encoder.encode(
                TimerRequest(session: session,
                             page: timer.page,
                             timer: timer.pageTimeInterval,
                             customMetrics: customMetrics,
                             trafficSegmentName: timer.trafficSegmentName,
                             purchaseConfirmation: purchase,
                             performanceReport: timer.performanceReport,
                             nativeAppProperties : timer.nativeAppProperties))

            return Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           body: body.base64EncodedData())
        }
    }
}
