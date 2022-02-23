//
//  CapturedRequestBuilder.swift
//
//  Created by Mathew Gacy on 2/22/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequestBuilder {
    let build: (Session, Page, PageTimeInterval, [CapturedRequest]) throws -> Request

    static func makeParameters(
        siteID: String,
        sessionID: String,
        trafficSegment: String,
        isNewUser: Bool,
        pageType: String,
        pageName: String,
        startTime: Millisecond,
        pageTime: Millisecond
    ) -> Request.Parameters {
        [
            "siteID": siteID,
            "nStart": String(startTime),
            "pageName": pageName,
            "txnName": trafficSegment,
            "sessionID": String(sessionID),
            "WCDtt": "c",
            "pgTm": String(pageTime),
            "NVSTR": isNewUser.smallIntString,
            "pageType": pageType
        ]
    }

    static var live: Self = CapturedRequestBuilder { session, page, interval, model in
        // TOOD: handle `isNewUser`; ask Joel if it should be part of `Session`
        let isNewUser = false

        let parameters = makeParameters(
            siteID: session.siteID,
            sessionID: String(session.sessionID),
            trafficSegment: session.trafficSegmentName,
            isNewUser: isNewUser,
            pageType: page.pageType,
            pageName: page.pageName,
            startTime: interval.startTime,
            pageTime: interval.pageTime)

        return try Request(method: .post,
                           url: Constants.capturedRequestEndpoint,
                           parameters: parameters,
                           model: model)
    }
}
