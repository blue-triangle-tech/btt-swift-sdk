//
//  CapturedRequestBuilder.swift
//
//  Created by Mathew Gacy on 2/22/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequestBuilder {
    let build: (Millisecond, Millisecond, RequestSpan) throws -> Request

    static func makeParameters(
        siteID: String,
        sessionID: String,
        trafficSegment: String,
        isNewUser: Bool,
        pageType: String,
        pageName: String,
        startTime: Millisecond
    ) -> Request.Parameters {
        [
            "siteID": siteID,
            "nStart": String(startTime),
            "pageName": pageName,
            "txnName": trafficSegment,
            "sessionID": String(sessionID),
            "WCDtt": "c",
            "NVSTR": isNewUser.smallIntString,
            "pageType": pageType,
            // FIXME: replace strings with pending `Constant` additions from master
            "os": "iOS",
            "browser": Constants.browserName,
            "device": "Mobile"
        ]
    }

    static func makeBuilder(sessionProvider: @escaping () -> Session) -> Self {
        .init { startTime, pageTime, requestSpan in
            let session = sessionProvider()

            // FIXME: use pending Session.isReturningVisitor property from master
            let isNewUser: Bool = false

            let parameters = CapturedRequestBuilder.makeParameters(
                siteID: session.siteID,
                sessionID: String(session.sessionID),
                trafficSegment: session.trafficSegmentName,
                isNewUser: isNewUser,
                pageType: requestSpan.page.pageType,
                pageName: requestSpan.page.pageName,
                startTime: startTime
            )

            return try Request(method: .post,
                               url: Constants.capturedRequestEndpoint,
                               parameters: parameters,
                               model: requestSpan.requests)
        }
    }
}
