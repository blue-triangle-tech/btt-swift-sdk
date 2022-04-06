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

    static var spanTimeIntervals: [TimeInterval] = []
    static var spanIntervalProvider: () -> TimeInterval = {
        spanTimeIntervals.popLast() ?? 0
    }

    static var timelineTimeIntervals: [TimeInterval] = []
    static var timelineIntervalProvider: () -> TimeInterval = {
        timelineTimeIntervals.popLast() ?? 0
    }

    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }

    static var logger: LoggerMock = .init()

    static var queue = DispatchQueue(label: "com.bluetriangle.network-capture",
                                     qos: .userInitiated,
                                     autoreleaseFrequency: .workItem)

    static var requestBuilder: CapturedRequestBuilder = .init { _, _ in
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
        Self.spanTimeIntervals = []
        Self.timelineTimeIntervals = []
        Self.timeIntervals = []
    }

    // MARK: -

    func testMakeTimerBeforeSpanStart() throws {
        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        let timer = collector.makeTimer()
        XCTAssertNil(timer)
    }

    func testMakeTimerAfterSpanStart() throws {
        Self.spanTimeIntervals = [
            1.0
        ]

        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        let spanTimer = Self.makeSpanTimer()
        spanTimer.start()

        collector.start(timer: spanTimer) { _ in }

        let timer1 = collector.makeTimer()
        let timer2 = collector.makeTimer()

        let expectedOffset: TimeInterval = 1.0
        XCTAssertEqual(timer1?.offset, expectedOffset)
        XCTAssertEqual(timer2?.offset, expectedOffset)
    }

    func testMakeTimerAfterMultipleSpanStarts() throws {
        Self.spanTimeIntervals = [
            // Start spanTimer2
            1.2,
            // End spanTimer1
            1.1,
            // Start spanTimer1
            1.0
        ]

        let collector = CapturedRequestCollector(
            storage: Timeline<RequestSpan>(),
            queue: Mock.requestCollectorQueue,
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        // Span 1
        let spanTimer1 = Self.makeSpanTimer()
        collector.start(timer: spanTimer1) { _ in }
        let timer1 = collector.makeTimer()

        // Span 2
        let spanTimer2 = Self.makeSpanTimer(page: .init(pageName: "Page 2"))
        collector.start(timer: spanTimer2) { _ in }
        let timer2 = collector.makeTimer()

        let expectedOffset1: TimeInterval = 1.0
        let expectedOffset2: TimeInterval = 1.2
        XCTAssertEqual(timer1?.offset, expectedOffset1)
        XCTAssertEqual(timer2?.offset, expectedOffset2)
    }

    func testSpanUploadAfterNewSpan() throws {
        Self.spanTimeIntervals = [
            // Start span 2
            1.3,
            // Start span 1
            1.0
        ]

        Self.timelineTimeIntervals = [
            // Insert span 2
            1.32,
            // batchCurrentRequests for span 1
            1.31,
            // Insert span 1
            1.01,
        ]

        Self.timeIntervals = [
            // End timer1
            1.2,
            // Start timer1
            1.1
        ]

        let timeline = Timeline<RequestSpan>(capacity: 2, intervalProvider: Self.timelineIntervalProvider)

        // Request Builder
        var startTime: Millisecond!
        var requestSpan: RequestSpan!
        let requestExpectation = expectation(description: "Request built")
        let requestBuilder: CapturedRequestBuilder = .init { start, span in
            startTime = start
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
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: requestBuilder,
            uploader: uploader)

        // Span 1
        let spanTimer1 = Self.makeSpanTimer()
        collector.start(timer: spanTimer1) { _ in }

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
        let spanTimer2 = Self.makeSpanTimer(page: .init(pageName: "Page 2"))
        collector.start(timer: spanTimer2) { _ in }

        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.makeCapturedRequest()
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }

    func testTimerUpload() throws {
        Self.spanTimeIntervals = [
            // Start spanTimer2
            2.01,
            // End spanTimer1
            2.0,
            // Start spanTimer1
            1.0
        ]

        let timeline = Timeline<RequestSpan>(intervalProvider: Self.timelineIntervalProvider)

        // Collector
        let collector = CapturedRequestCollector(
            storage: timeline,
            queue: Mock.requestCollectorQueue,
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())

        // Span 1
        let spanTimer1 = Self.makeSpanTimer(page: Mock.page)
        collector.start(timer: spanTimer1) { _ in }

        // Span 2
        let spanTimer2 = Self.makeSpanTimer(page: .init(pageName: "Page 2"))

        var timerToUpload: BTTimer!
        let timerExpectation = expectation(description: "")
        collector.start(timer: spanTimer2) { timer in
            timerToUpload = timer
            timerExpectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        let expectedStartTime: TimeInterval = 1.0
        let expectedEndTime: TimeInterval = 2.0

        XCTAssertEqual(timerToUpload.page, Mock.page)
        XCTAssertEqual(timerToUpload.startTime, expectedStartTime)
        XCTAssertEqual(timerToUpload.endTime, expectedEndTime)
    }

    func testSpanPoppingSpan() throws {
        Self.spanTimeIntervals = [
            // Start span 3 + pop
            3.0,
            // Start span 2
            2.0,
            // Start span 1
            1.0
        ]

        Self.timelineTimeIntervals = [
            // Insert span 3
            3.01,
            // Insert span 2
            2.01,
            // Insert span 1
            1.01,
        ]

        Self.timeIntervals = [
            // End timer1
            2.5,
            // Start timer1
            1.1
        ]

        let timeline = Timeline<RequestSpan>(capacity: 2, intervalProvider: Self.timelineIntervalProvider)

        // Request Builder
        var startTime: Millisecond!
        var requestSpan: RequestSpan!
        let requestExpectation = expectation(description: "Request built")
        let requestBuilder: CapturedRequestBuilder = .init { start, span in
            startTime = start
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
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: requestBuilder,
            uploader: uploader)

        // Span 1
        let spanTimer1 = Self.makeSpanTimer()
        collector.start(timer: spanTimer1) { _ in }

        // Make request
        var timer1: InternalTimer! = collector.makeTimer()
        timer1.start()

        // Span 2
        let spanTimer2 = Self.makeSpanTimer(page: .init(pageName: "Page 2"))
        collector.start(timer: spanTimer2) { _ in }

        // Receive response
        timer1.end()
        let data = Data()
        let response = HTTPURLResponse(
            url: URL(string: Mock.capturedRequestURLString)!,
            mimeType: nil,
            expectedContentLength: 100,
            textEncodingName: nil)

        collector.collect(timer: timer1, data: data, response: response)

        // Span 3
        let spanTimer3 = Self.makeSpanTimer(page: .init(pageName: "Page 3"))
        collector.start(timer: spanTimer3) { _ in }

        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.makeCapturedRequest(endTime: 1500)
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }

    func testBatchCapturedRequests() {
        Self.spanTimeIntervals = [
            // Start span 1
            1.0
        ]

        Self.timelineTimeIntervals = [
            // Batch requests
            2.01,
            // Insert span 1
            1.01
        ]

        Self.timeIntervals = [
            // End timer1
            1.2,
            // Start timer1
            1.1
        ]

        let timeline = Timeline<RequestSpan>(capacity: 2, intervalProvider: Self.timelineIntervalProvider)

        let timerStartExpectation = expectation(description: "Timer started")
        let timerManager = CaptureTimerManagerMock(onStart: {
            timerStartExpectation.fulfill()
        })

        // Request Builder
        var startTime: Millisecond!
        var requestSpan: RequestSpan!
        let requestExpectation = expectation(description: "Request built")
        let requestBuilder: CapturedRequestBuilder = .init { start, span in
            startTime = start
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
            logger: Self.logger,
            timerManager: timerManager,
            timeIntervalProvider: Self.timeIntervalProvider,
            requestBuilder: requestBuilder,
            uploader: uploader)

        // Span 1
        let spanTimer1 = Self.makeSpanTimer()
        collector.start(timer: spanTimer1) { _ in }

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

        // Batch requests
        timerManager.handler?()

        waitForExpectations(timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.makeCapturedRequest(endTime: 200)
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }
}

extension RequestCollectorTests {
    static func makeSpanTimer(page: Page = Mock.page) -> BTTimer {
        BTTimer(
           page: page,
           logger: logger,
           intervalProvider: spanIntervalProvider,
           performanceMonitor: nil)
    }
}
