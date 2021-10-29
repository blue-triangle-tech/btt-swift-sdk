//
//  Mock.swift
//
//  Created by Mathew Gacy on 10/15/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine
@testable import BlueTriangle

// MARK: - Response
enum Mock {
    typealias Response = (data: Data, response: HTTPURLResponse)

    struct TestError: Error {}

    static let errorJSON = """
          {
            "error": "someError"
          }
          """.data(using: .utf8)!

    static let successJSON = """
          {
            "foo": "bar"
          }
          """.data(using: .utf8)!

    static func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: "https://example.com",
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil)!
    }

    static var successResponse = HTTPResponse<Data>(
        value: successJSON,
        response: makeHTTPResponse(statusCode: 200))

    static var errorResponse = HTTPResponse<Data>(
        value: errorJSON,
        response: makeHTTPResponse(statusCode: 400))

    static var urlSuccessResponse = Response(
        data: successJSON,
        response: makeHTTPResponse(statusCode: 200))

    static var urlErrorResponse = Response(
        data: errorJSON,
        response: makeHTTPResponse(statusCode: 400))

}

// MARK: - Configuration
extension Mock {

    static var uploaderQueue: DispatchQueue {
        DispatchQueue(label: "com.bluetriangle.uploader",
                      qos: .userInitiated,
                      autoreleaseFrequency: .workItem)
    }

    static func configureBlueTriangle(configuration config: BlueTriangleConfiguration) {
        config.siteID = "MY_SITE_ID"
        config.sessionID = Mock.sessionID
        config.globalUserID = Mock.globalUserID
        config.abTestID = "MY_AB_TEST_ID"
        config.campaignMedium = "MY_CAMPAIGN_MEDIUM"
        config.campaignName = "MY_CAMPAIGN_NAME"
        config.campaignSource = "MY_CAMPAIGN_SOURCE"
        config.dataCenter = "MY_DATA_CENTER"
        config.trafficSegmentName = "MY_SEGMENT_NAME"
    }

    static func makeRequestBuilder(
        onBuild: @escaping (Session, BTTimer) -> Void = { _, _ in }
    ) -> RequestBuilder {
        RequestBuilder { session, timer in
            onBuild(session, timer)
            return Request(method: .post, url: "https://example.com")
        }
    }

    static var retryConfiguration = Uploader.RetryConfiguration<DispatchQueue>(maxRetry: 2,
                                                                               initialDelay: 0.1,
                                                                               delayMultiplier: 0.1,
                                                                               shouldRetry: nil)

    static func makeUploaderConfiguration(
        queue: DispatchQueue,
        onSend: @escaping (Request) -> Void = {_ in }
    ) -> Uploader.Configuration {
        Uploader.Configuration(
            queue: queue,
            log: { print($0) },
            networking: { request in
                Deferred {
                    Future { promise in
                        onSend(request)
                        promise(.success(Mock.successResponse))
                    }
                }.eraseToAnyPublisher()
            },
            retryConfiguration: retryConfiguration)
    }

    static func makeTimerConfiguration(
        intervalProvider: @escaping () -> TimeInterval
    ) ->  BTTimer.Configuration {
        BTTimer.Configuration(
            logProvider: { print($0) },
            timeIntervalProvider: intervalProvider
        )
    }
}

// MARK: - Models
extension Mock {

    static var customCategories = CustomCategories(
        cv6: "CV6",
        cv7: "CV7",
        cv8: "CV8",
        cv9: "CV9",
        cv10: "CV10")

    static var customNumbers = CustomNumbers(
        cn1: 1.11,
        cn2: 2.22,
        cn3: 3.33,
        cn4: 4.44,
        cn5: 5.55,
        cn6: 6.66,
        cn7: 7.77,
        cn8: 8.88,
        cn9: 9.99,
        cn10: 10.10,
        cn11: 11.11,
        cn12: 12.12,
        cn13: 13.13,
        cn14: 14.14,
        cn15: 15.15,
        cn16: 16.16,
        cn17: 17.17,
        cn18: 18.18,
        cn19: 19.19,
        cn20: 20.20)

    static var customVariables = CustomVariables(
        cv1: "CV1",
        cv2: "CV2",
        cv3: "CV3",
        cv4: "CV4",
        cv5: "CV5",
        cv11: "CV11",
        cv12: "CV12",
        cv13: "CV13",
        cv14: "CV14",
        cv15: "CV15")

    static var globalUserID: Identifier = 888_888_888_888_888_888

    static var sessionID: Identifier = 999_999_999_999_999_999

    static var page = Page(
        pageName: "MY_PAGE_NAME",
        brandValue: 0.51,
        pageType: "MY_PAGE_TYPE",
        referringURL: "MY_REFERRING_URL",
        url: "MY_URL",
        customVariables: Mock.customVariables,
        customCategories: Mock.customCategories,
        customNumbers: Mock.customNumbers)

    static var purchaseConfirmation = PurchaseConfirmation(
        cartValue: 99.99,
        orderNumber: "MY_ORDER_NUMBER",
        orderTime: 0.0)

    static var header: Request.Headers = [
        "Host": "example.com",
        "Content-Type": "application/x-www-form-urlencoded",
        "Connection": "keep-alive",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br"
    ]

    static var request = Request(
        method: .post,
        url: "http://example.com",
        headers: Mock.header,
        body: Mock.successJSON)

    static var session = Session(
        siteID: "MY_SITE_ID",
        globalUserID: Mock.globalUserID,
        sessionID: Mock.sessionID,
        abTestID: "MY_AB_TEST_ID",
        campaign: "MY_CAMPAIGN",
        campaignMedium: "MY_CAMPAIGN_MEDIUM",
        campaignName: "MY_CAMPAIGN_NAME",
        campaignSource: "MY_CAMPAIGN_SOURCE",
        dataCenter: "MY_DATA_CENTER",
        trafficSegmentName: "MY_SEGMENT_NAME")

    static var timerInterval = PageTimeInterval(
        startTime: 2000,
        interactiveTime: 3000,
        pageTime: 1000)

    static var timerRequest = TimerRequest(
        session: Mock.session,
        page: Mock.page,
        timer: Mock.timerInterval,
        purchaseConfirmation: Mock.purchaseConfirmation)
}

// MARK: - Request
extension Mock {

    static func makeRequestJSON(appVersion: String, os: String, osVersion: String) -> String {
        return """
        {
            "AB": "MY_AB_TEST_ID",
            "bv": 0.51,
            "bvzn": "Native App-\(appVersion)-\(os) \(osVersion)",
            "campaign": null,
            "CmpM": "MY_CAMPAIGN_MEDIUM",
            "CmpN": "MY_CAMPAIGN_NAME",
            "CmpS": "MY_CAMPAIGN_SOURCE",
            "CN1": 1.11,
            "CN10": 10.1,
            "CN11": 11.11,
            "CN12": 12.12,
            "CN13": 13.13,
            "CN14": 14.14,
            "CN15": 15.15,
            "CN16": 16.16,
            "CN17": 17.17,
            "CN18": 18.18,
            "CN19": 19.19,
            "CN2": 2.22,
            "CN20": 20.2,
            "CN3": 3.33,
            "CN4": 4.44,
            "CN5": 5.55,
            "CN6": 6.66,
            "CN7": 7.77,
            "CN8": 8.88,
            "CN9": 9.99,
            "CV1": "CV1",
            "CV10": "CV10",
            "CV11": "CV11",
            "CV12": "CV12",
            "CV13": "CV13",
            "CV14": "CV14",
            "CV15": "CV15",
            "CV2": "CV2",
            "CV3": "CV3",
            "CV4": "CV4",
            "CV5": "CV5",
            "CV6": "CV6",
            "CV7": "CV7",
            "CV8": "CV8",
            "CV9": "CV9",
            "DCTR": "MY_DATA_CENTER",
            "domInteractive": 1000000,
            "EUOS": "iOS",
            "eventType": 9,
            "gID": 888888888888888888,
            "navigationType": 9,
            "nst": 0,
            "pageName": "MY_PAGE_NAME",
            "pageType": "MY_PAGE_TYPE",
            "pgTm": 2000000,
            "referrer": "MY_REFERRING_URL",
            "RV": 0,
            "sID": 999999999999999999,
            "siteID": "MY_SITE_ID",
            "thisURL": "MY_URL",
            "txnName": "MY_SEGMENT_NAME",
            "unloadEventStart": 0,
            "wcd": 0
        }
        """
    }
}
