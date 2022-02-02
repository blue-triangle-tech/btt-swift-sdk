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
        onBuild: @escaping (Session, BTTimer, PurchaseConfirmation?) -> Void = { _, _, _ in }
    ) -> RequestBuilder {
        RequestBuilder { session, timer, purchaseConfirmation in
            onBuild(session, timer, purchaseConfirmation)
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
            timeIntervalProvider: intervalProvider
        )
    }

    static func makePerformanceMonitor(timerInterval: TimeInterval) -> PerformanceMonitoring {
        PerformanceMonitorMock()
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
        orderNumber: "MY_ORDER_NUMBER")

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
        purchaseConfirmation: Mock.purchaseConfirmation,
        performanceReport: nil)

    static var performanceReport = PerformanceReport(
        minCPU: 0.0,
        maxCPU: 0.0,
        avgCPU: 0.0,
        minMemory: 0,
        maxMemory: 0,
        avgMemory: 0)
}

// MARK: - Request
extension Mock {

    static func makeRequestJSON(appVersion: String, os: String, osVersion: String) -> String {
        """
{\"pgTm\":2000000,\"AB\":\"MY_AB_TEST_ID\",\"CN10\":10.1,\"CN8\":8.8800000000000008,\"CV13\":\"CV13\",\"siteID\":\"MY_SITE_ID\",\"CN9\":9.9900000000000002,\"CN18\":18.18,\"thisURL\":\"MY_URL\",\"pageType\":\"MY_PAGE_TYPE\",\"CN11\":11.109999999999999,\"campaign\":null,\"eventType\":9,\"CV14\":\"CV14\",\"CV1\":\"CV1\",\"CN19\":19.190000000000001,\"CN12\":12.119999999999999,\"CV2\":\"CV2\",\"maxCPU\":100,\"CV15\":\"CV15\",\"CmpS\":\"MY_CAMPAIGN_SOURCE\",\"txnName\":\"MY_SEGMENT_NAME\",\"CV3\":\"CV3\",\"minMemory\":10000000,\"EUOS\":\"\(os)\",\"sID\":999999999999999999,\"CN13\":13.130000000000001,\"CV4\":\"CV4\",\"CN20\":20.199999999999999,\"avgMemory\":50000000,\"CV5\":\"CV5\",\"CN1\":1.1100000000000001,\"CmpM\":\"MY_CAMPAIGN_MEDIUM\",\"CN14\":14.140000000000001,\"nst\":0,\"navigationType\":9,\"CV6\":\"CV6\",\"avgCPU\":50,\"CN2\":2.2200000000000002,\"CV7\":\"CV7\",\"CV10\":\"CV10\",\"CN3\":3.3300000000000001,\"CmpN\":\"MY_CAMPAIGN_NAME\",\"unloadEventStart\":0,\"CN15\":15.15,\"CV8\":\"CV8\",\"CN4\":4.4400000000000004,\"wcd\":0,\"gID\":888888888888888888,\"RV\":0,\"CV9\":\"CV9\",\"CV11\":\"CV11\",\"CN5\":5.5499999999999998,\"domInteractive\":1000000,\"CN16\":16.16,\"minCPU\":1,\"bvzn\":\"Native App-\(appVersion)-\(os) \(osVersion)\",\"CN6\":6.6600000000000001,\"referrer\":\"MY_REFERRING_URL\",\"bv\":0.51,\"CV12\":\"CV12\",\"maxMemory\":100000000,\"CN7\":7.7699999999999996,\"CN17\":17.170000000000002,\"pageName\":\"MY_PAGE_NAME\",\"DCTR\":\"MY_DATA_CENTER\"}
"""
    }
}

class LoggerMock: Logging {
    var onInfo: (String) -> Void
    var onError: (String) -> Void

    init(onInfo: @escaping (String) -> Void = { _ in }, onError: @escaping (String) -> Void = { _ in }) {
        self.onInfo = onInfo
        self.onError = onError
    }

    func logInfo(_ message: @autoclosure () -> String, file: StaticString, function: StaticString, line: UInt) {
        onInfo(message())
    }

    func logError(_ message: @autoclosure () -> String, file: StaticString, function: StaticString, line: UInt) {
        onError(message())
    }

    func reset() {
        onInfo = { _ in }
        onError = { _ in }
    }
}

class PerformanceMonitorMock: PerformanceMonitoring {
    var report: PerformanceReport
    var onStart: () -> Void
    var onEnd: () -> Void

    init(
        report: PerformanceReport = Mock.performanceReport,
        onStart: @escaping () -> Void = { },
        onEnd: @escaping () -> Void = { }
    ) {
        self.report = report
        self.onStart = onStart
        self.onEnd = onEnd
    }

    func start() {
        onStart()
    }

    func end() {
        onEnd()
    }

    func makeReport() -> PerformanceReport {
        report
    }

    func reset() {
        report = Mock.performanceReport
        onStart = { }
        onEnd = { }
    }
}

struct ResourceUsageMock: ResourceUsageMeasuring {
    static func cpu() -> Double {
        0.25
    }

    static func memory() -> UInt64 {
        100
    }
}
