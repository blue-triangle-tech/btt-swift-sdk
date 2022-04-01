//
//  RequestCollectorTests.swift
//
//  Created by Mathew Gacy on 3/2/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest
@testable import BlueTriangle

class RequestCollectorTests: XCTestCase {
    static var uploaderQueue: DispatchQueue = Mock.uploaderQueue
    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }
    static var logger: LoggerMock = .init()

    static var queue = DispatchQueue(label: "com.bluetriangle.network-capture",
                                     qos: .userInitiated,
                                     autoreleaseFrequency: .workItem)

    static var requestBuilder: CapturedRequestBuilder = .init { _, _, _ in
        return Request(method: .post, url: Constants.capturedRequestEndpoint)
    }

    override class func tearDown() {
        BlueTriangle.reset()
    }

    override func setUp() {
        super.setUp()
        Self.timeIntervals = [
            1.5,
            1.4,
            1.3,
            1.2,
            1.1,
            1.0
        ]
    }

    override func tearDown() {
        super.tearDown()
        Self.timeIntervals = []
    }

    // MARK: -

    func testMakeTimerBeforeSpanStart() throws {
        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: LoggerMock(),
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())


        let timer = collector.makeTimer()
        XCTAssertNil(timer)
    }

    func testMakeTimerAfterSpanStart() throws {
        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: LoggerMock(),
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        let expectedOffset: TimeInterval = 1.0

        collector.start(page: Mock.page)

        let timer1 = collector.makeTimer()
        let timer2 = collector.makeTimer()

        XCTAssertEqual(timer1?.offset, expectedOffset)
        XCTAssertEqual(timer2?.offset, expectedOffset)
    }

    func testMakeTimerAfterMultipleSpanStarts() throws {
        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: LoggerMock(),
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        let expectedOffset1: TimeInterval = 1.0
        let expectedOffset2: TimeInterval = 1.1

        collector.start(page: Mock.page)
        let timer1 = collector.makeTimer()

        collector.start(page: Mock.page)
        let timer2 = collector.makeTimer()

        XCTAssertEqual(timer1?.offset, expectedOffset1)
        XCTAssertEqual(timer2?.offset, expectedOffset2)
    }

    func testSpanPoppingSpan() throws {
        Self.timeIntervals = [
            1.5,
            1.4,
            // Start span 2
            1.3,
            // End timer1
            1.2,
            // Start timer1
            1.1,
            // Start span 1
            1.0
        ]

        // Timeline
        var timelineIntervals: [TimeInterval] = [
            1.51,
            // Insert span 2
            1.32,
            // batchCurrentRequests for span 1
            1.31,
            // Insert span 1
            1.01,
        ]
        let timelineIntervalProvider: () -> TimeInterval = {
            timelineIntervals.popLast() ?? 0
        }
        let timeline = Timeline<RequestSpan>(capacity: 2, intervalProvider: timelineIntervalProvider)

        // Request Builder
        var startTime: Millisecond!
        var endTime: Millisecond!
        var requestSpan: RequestSpan!
        let requestExpectation = expectation(description: "Request built")
        let requestBuilder: CapturedRequestBuilder = .init { start, end, span in
            startTime = start
            endTime = end
            requestSpan = span

            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        // Uploader
        let uploadExpectation = expectation(description: "Request sent")
        let uploader = UploaderMock { req in
            uploadExpectation.fulfill()
        }

        // Collector
        let collector = CapturedRequestCollector(
            storage: timeline,
            queue: Mock.requestCollectorQueue,
            logger: LoggerMock(),
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: requestBuilder,
            uploader: uploader)

        // Span 1
        collector.start(page: Mock.page)

        // Make request
        var timer1: InternalTimer! = collector.makeTimer()
        timer1.start()

        // Receive response
        timer1.end()
        let data = Data()
        let response = HTTPURLResponse(
            url: URL(string: Mock.capturedRequestURLString)!,
            mimeType: nil,
            expectedContentLength: 100,
            textEncodingName: nil)

        collector.collect(timer: timer1, data: data, response: response)

        // Span 2
        collector.start(page: .init(pageName: "Page 2"))


        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedEndTime: Millisecond = 1310
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.capturedRequest
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(endTime, expectedEndTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }
}
