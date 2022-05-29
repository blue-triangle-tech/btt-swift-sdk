//
//  Mock.swift
//
//  Created by Mathew Gacy on 10/15/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine
import XCTest
@testable import BlueTriangle

// swiftlint:disable line_length

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

    static func makeHTTPResponse(
        url: URL = "https://example.com",
        statusCode: Int = 200,
        headerFields: [String: String]? = nil
    ) -> HTTPURLResponse {
        HTTPURLResponse(url: url,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: headerFields)!
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
        config.siteID = session.siteID
        config.globalUserID = session.globalUserID
        config.sessionID = session.sessionID
        config.isReturningVisitor = session.isReturningVisitor
        config.abTestID = session.abTestID
        config.campaignMedium = session.campaignMedium
        config.campaignName = session.campaignName
        config.campaignSource = session.campaignSource
        config.dataCenter = session.dataCenter
        config.trafficSegmentName = session.trafficSegmentName
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
        onSend: @escaping (Request) -> Void = { _ in }
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
    ) -> BTTimer.Configuration {
        BTTimer.Configuration(
            timeIntervalProvider: intervalProvider
        )
    }

    static func makePerformanceMonitor(timerInterval: TimeInterval) -> PerformanceMonitoring {
        PerformanceMonitorMock()
    }

    static func makeRequestCollectorConfiguration(
        queue: DispatchQueue = Self.requestCollectorQueue,
        timeIntervalProvider: @escaping () -> TimeInterval,
        timerManagingProvider: @escaping (NetworkCaptureConfiguration) -> CaptureTimerManaging = { _ in CaptureTimerManagerMock() }
    ) -> CapturedRequestCollector.Configuration {
        .init(queue: queue,
              timeIntervalProvider: timeIntervalProvider,
              timerManagingProvider: timerManagingProvider)
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
        isReturningVisitor: true,
        abTestID: "MY_AB_TEST_ID",
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

    static let capturedRequestURLString = "https://d33wubrfki0l68.cloudfront.net/f50c058607f066d0231c1fe6753eac79f17ea447/e6748/static/logo-cw.f6eaf6dc.png"

    static func makeCapturedRequest(
        startTime: Millisecond = 100,
        endTime: Millisecond = 200
    ) -> CapturedRequest {
        CapturedRequest(
            domain: "cloudfront.net",
            host:  "d33wubrfki0l68",
            url: capturedRequestURLString,
            file: "logo-cw.f6eaf6dc.png",
            startTime: startTime,
            endTime: endTime,
            duration: endTime - startTime,
            initiatorType: .image,
            decodedBodySize: 0,
            encodedBodySize: 100)
    }
}

// MARK: - Request
extension Mock {
    static var capturedRequestJSON = "[{\"f\":\"foo.json\",\"ez\":-1,\"h\":\"example\",\"d\":1000,\"dz\":0,\"sT\":2000,\"e\":\"resource\",\"i\":\"other\",\"dmn\":\"example.com\",\"URL\":\"https:\\/\\/example.com\\/foo.json\",\"rE\":3000}]"

    static func makeTimerRequestJSON(appVersion: String, os: String, osVersion: String) -> String {
        """
{\"pgTm\":2000000,\"AB\":\"MY_AB_TEST_ID\",\"CN10\":10.1,\"CN8\":8.8800000000000008,\"CV13\":\"CV13\",\"siteID\":\"MY_SITE_ID\",\"CN9\":9.9900000000000002,\"CN18\":18.18,\"thisURL\":\"MY_URL\",\"pageType\":\"MY_PAGE_TYPE\",\"CN11\":11.109999999999999,\"campaign\":null,\"eventType\":9,\"CV14\":\"CV14\",\"CV1\":\"CV1\",\"CN19\":19.190000000000001,\"CN12\":12.119999999999999,\"CV2\":\"CV2\",\"maxCPU\":100,\"CV15\":\"CV15\",\"os\":\"iOS\",\"CmpS\":\"MY_CAMPAIGN_SOURCE\",\"txnName\":\"MY_SEGMENT_NAME\",\"CV3\":\"CV3\",\"minMemory\":10000000,\"EUOS\":\"\(os)\",\"sID\":999999999999999999,\"CN13\":13.130000000000001,\"CV4\":\"CV4\",\"CN20\":20.199999999999999,\"avgMemory\":50000000,\"CV5\":\"CV5\",\"CN1\":1.1100000000000001,\"CmpM\":\"MY_CAMPAIGN_MEDIUM\",\"CN14\":14.140000000000001,\"nst\":0,\"navigationType\":9,\"device\":\"Mobile\",\"CV6\":\"CV6\",\"CN2\":2.2200000000000002,\"avgCPU\":50,\"CV7\":\"CV7\",\"CV10\":\"CV10\",\"CN3\":3.3300000000000001,\"CmpN\":\"MY_CAMPAIGN_NAME\",\"unloadEventStart\":0,\"CN15\":15.15,\"CV8\":\"CV8\",\"CN4\":4.4400000000000004,\"wcd\":0,\"gID\":888888888888888888,\"RV\":1,\"CV9\":\"CV9\",\"RefURL\":\"MY_REFERRING_URL\",\"CN5\":5.5499999999999998,\"CV11\":\"CV11\",\"domInteractive\":1000000,\"CN16\":16.16,\"browser\":\"Native App\",\"minCPU\":1,\"bvzn\":\"Native App-\(appVersion)-\(os) \(osVersion)\",\"CN6\":6.6600000000000001,\"bv\":0.51,\"CV12\":\"CV12\",\"maxMemory\":100000000,\"CN7\":7.7699999999999996,\"CN17\":17.170000000000002,\"pageName\":\"MY_PAGE_NAME\",\"DCTR\":\"MY_DATA_CENTER\"}
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
    var measurementCount: Int = 10

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

class CaptureTimerManagerMock: CaptureTimerManaging {
    var onStart: () -> Void
    var onCancel: () -> Void
    var handler: (() -> Void)?

    init(
        onStart: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        handler: @escaping () -> Void  = {}
    ) {
        self.onStart = onStart
        self.onCancel = onCancel
        self.handler = handler
    }

    func start() {
        onStart()
    }

    func cancel() {
        onCancel()
    }

    func fireTimer() {
        handler?()
    }
}

struct UploaderMock: Uploading {
    var onSend: (Request) -> Void = { _ in }

    init(onSend: @escaping (Request) -> Void = { _ in }) {
        self.onSend = onSend
    }

    func send(request: Request) {
        onSend(request)
    }
}

final class URLProtocolMock: URLProtocol {
    static var responseQueue: DispatchQueue = .global()
    static var responseDelay: TimeInterval? = 0.3
    static var responseProvider: (URL) throws -> (Data, HTTPURLResponse) = { url in
        (Data(), Mock.makeHTTPResponse(url: url))
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let delay = Self.responseDelay {
            guard client != nil else { return }
            Self.responseQueue.asyncAfter(deadline: .now() + delay) {
                self.respond()
            }
        } else {
            respond()
        }
    }

    override func stopLoading() { }

    private func respond() {
        guard let client = client else { return }
        do {
            let url = try XCTUnwrap(request.url)
            let response = try Self.responseProvider(url)
            client.urlProtocol(self, didReceive: response.1, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: response.0)
        } catch {
            client.urlProtocol(self, didFailWithError: error)
        }
        client.urlProtocolDidFinishLoading(self)
    }
}

extension URLSessionConfiguration {
    static var mock: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        return config
    }
}
