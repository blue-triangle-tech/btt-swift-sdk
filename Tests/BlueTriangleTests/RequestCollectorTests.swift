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

    func testSpanUploadAfterNewSpan() throws {
        Self.timeIntervals = [
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
            Mock.makeCapturedRequest()
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(endTime, expectedEndTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }

    func testSpanPoppingSpan() throws {
        Self.timeIntervals = [
            // Start span 3 + pop
            3.0,
            // End timer1
            2.5,
            // Start span 2
            2.0,
            // Start timer1
            //1.5,
            1.1,
            // Start span 1
            1.0
        ]

        // Timeline
        var timelineIntervals: [TimeInterval] = [
            // Insert span 3
            3.01,
            // Insert span 2
            2.01,
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

        // Span 2
        collector.start(page: .init(pageName: "Span 2"))

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
        collector.start(page: .init(pageName: "Page 3"))

        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedEndTime: Millisecond = 3010
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.makeCapturedRequest(endTime: 1500)
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(endTime, expectedEndTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }

    func testBatchCapturedRequests() {
        Self.timeIntervals = [
            // End timer1
            1.2,
            // Start timer1
            1.1,
            // Start span 1
            1.0
        ]

        // Timeline
        var timelineIntervals: [TimeInterval] = [
            // Batch requests
            2.01,
            // Insert span 1
            1.01
        ]
        let timelineIntervalProvider: () -> TimeInterval = {
            timelineIntervals.popLast() ?? 0
        }
        let timeline = Timeline<RequestSpan>(capacity: 2, intervalProvider: timelineIntervalProvider)

        let timerStartExpectation = expectation(description: "Timer started")
        let timerManager = CaptureTimerManagerMock(onStart: {
            timerStartExpectation.fulfill()
        })

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
            timerManager: timerManager,
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

        // Batch requests
        timerManager.handler?()

        waitForExpectations(timeout: 1.0)

        let expectedStartTime: Millisecond = 1010
        let expectedEndTime: Millisecond = 2010
        let expectedPage = Mock.page
        let expectedRequests: [CapturedRequest] = [
            Mock.makeCapturedRequest(endTime: 200)
        ]

        XCTAssertEqual(startTime, expectedStartTime)
        XCTAssertEqual(endTime, expectedEndTime)
        XCTAssertEqual(requestSpan.page, expectedPage)
        XCTAssertEqual(requestSpan.requests, expectedRequests)
    }
}
