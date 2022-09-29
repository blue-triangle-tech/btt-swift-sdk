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
    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }

    static var logger: LoggerMock = .init()

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

    func testTimerManagerCalls() async throws {
        let timerManager = CaptureTimerManagerMock()

        var cancelExpectation: XCTestExpectation? = expectation(description: "Timer Manager Cancelled")
        timerManager.onCancel = {
            cancelExpectation?.fulfill()
        }

        let startExpectation = expectation(description: "Timer Manager Started")
        timerManager.onStart = {
            startExpectation.fulfill()
        }

        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: timerManager,
            requestBuilder: Self.requestBuilder,
            uploader: UploaderMock())
        await collector.configure()

        await collector.start(page: Mock.page, startTime: 1.0)

        wait(for: [cancelExpectation!], timeout: 0.1)
        wait(for: [startExpectation], timeout: 0.1)
        // Accommodate timer manager cancel on deinit
        cancelExpectation = nil
    }

    func testUploadAfterStart() async throws {
        var actualStartTime: Millisecond!
        var actualPage: Page!
        var actualRequests: [CapturedRequest]!
        let requestExpectation = expectation(description: "Request Built")
        let requestBuilder: CapturedRequestBuilder = .init { startTime, page, requests in
            actualStartTime = startTime
            actualPage = page
            actualRequests = requests
            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        let uploadExpectation = expectation(description: "Captured Requests uploaded")
        let uploader = UploaderMock { _ in
            uploadExpectation.fulfill()
        }

        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            requestBuilder: requestBuilder,
            uploader: uploader)
        await collector.configure()

        // Start BTTimer
        let expectedPage = Mock.page
        let expectedStartTime = 0.9
        await collector.start(page: expectedPage, startTime: expectedStartTime)

        // Start / End Request
        var requestTimer = InternalTimer(logger: Self.logger, intervalProvider: Self.timeIntervalProvider)
        requestTimer.start()
        requestTimer.end()
        let response = Mock.makeCapturedResponse()
        await collector.collect(timer: requestTimer, response: response)

        // Start another timer
        await collector.start(page: Page(pageName: "Another_Page"), startTime: 2.0)

        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        XCTAssertEqual(actualStartTime, expectedStartTime.milliseconds)
        XCTAssertEqual(actualPage, expectedPage)
        XCTAssertEqual(actualRequests, [Mock.makeCapturedRequest()])
    }

    func testUploadEmptyAfterStart() async throws {
        let requestExpectation = expectation(description: "Request Built")
        requestExpectation.isInverted = true
        let requestBuilder: CapturedRequestBuilder = .init { _, _, _ in
            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        let uploadExpectation = expectation(description: "Captured Requests uploaded")
        uploadExpectation.isInverted = true
        let uploader = UploaderMock { _ in
            uploadExpectation.fulfill()
        }

        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: CaptureTimerManagerMock(),
            requestBuilder: requestBuilder,
            uploader: uploader)
        await collector.configure()

        // Start BTTimer
        await collector.start(page: Mock.page, startTime: 0.9)

        // Start another timer
        await collector.start(page: Page(pageName: "Another_Page"), startTime: 2.0)

        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)
    }

    func testTimerManagerHandlerBatches() async throws {
        var actualStartTime: Millisecond!
        var actualPage: Page!
        var actualRequests: [CapturedRequest]!
        let requestExpectation = expectation(description: "Request Built")
        let requestBuilder: CapturedRequestBuilder = .init { startTime, page, requests in
            actualStartTime = startTime
            actualPage = page
            actualRequests = requests
            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        let uploadExpectation = expectation(description: "Captured Requests uploaded")
        let uploader = UploaderMock { _ in
            uploadExpectation.fulfill()
        }

        let timerManager = CaptureTimerManagerMock()
        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: timerManager,
            requestBuilder: requestBuilder,
            uploader: uploader)
        await collector.configure()

        // Start BTTimer
        let expectedPage = Mock.page
        let expectedStartTime = 0.9
        await collector.start(page: expectedPage, startTime: expectedStartTime)

        // Capture Request
        var requestTimer = InternalTimer(logger: Self.logger, intervalProvider: Self.timeIntervalProvider)
        requestTimer.start()
        requestTimer.end()
        let response = Mock.makeCapturedResponse()
        await collector.collect(timer: requestTimer, response: response)

        timerManager.fireTimer()

        try await Task.sleep(nanoseconds: 1.0.nanoseconds)
        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        XCTAssertEqual(actualStartTime, expectedStartTime.milliseconds)
        XCTAssertEqual(actualPage, expectedPage)
        XCTAssertEqual(actualRequests, [Mock.makeCapturedRequest()])
    }

    func testTimerManagerHandlerEmptyBatches() async throws {
        let requestExpectation = expectation(description: "Request Built")
        requestExpectation.isInverted = true
        let requestBuilder: CapturedRequestBuilder = .init { _, _, _ in
            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        let uploadExpectation = expectation(description: "Captured Requests uploaded")
        uploadExpectation.isInverted = true
        let uploader = UploaderMock { _ in
            uploadExpectation.fulfill()
        }

        let timerManager = CaptureTimerManagerMock()
        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: timerManager,
            requestBuilder: requestBuilder,
            uploader: uploader)
        await collector.configure()

        // Start BTTimer
        let expectedPage = Mock.page
        let expectedStartTime = 0.9
        await collector.start(page: expectedPage, startTime: expectedStartTime)

        timerManager.fireTimer()

        try await Task.sleep(nanoseconds: 1.0.nanoseconds)
        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)
    }

    func testRequestBuilderError() async throws {
        struct TestError: Error { }

        let logErrorExpectation = expectation(description: "Error Logged")
        let logger = LoggerMock(onError: { _ in
            logErrorExpectation.fulfill()
        })

        let requestBuilder: CapturedRequestBuilder = .init { _, _, _ in
            throw TestError()
        }

        let timerManager = CaptureTimerManagerMock()
        let collector = CapturedRequestCollector(
            logger: logger,
            timerManager: timerManager,
            requestBuilder: requestBuilder,
            uploader: UploaderMock())
        await collector.configure()

        // Start BTTimer
        await collector.start(page: Mock.page, startTime: 0.9)

        // Start / End Request
        var requestTimer = InternalTimer(logger: Self.logger, intervalProvider: Self.timeIntervalProvider)
        requestTimer.start()
        requestTimer.end()
        let response = Mock.makeCapturedResponse()
        await collector.collect(timer: requestTimer, response: response)

        await collector.start(page: Page(pageName: "Another_Page"), startTime: 2.0)

        wait(for: [logErrorExpectation], timeout: 1.0)
    }

    func testMultipleConfigureCalls() async throws {
        var actualStartTime: Millisecond!
        var actualPage: Page!
        var actualRequests: [CapturedRequest]!
        let requestExpectation = expectation(description: "Request Built")
        let requestBuilder: CapturedRequestBuilder = .init { startTime, page, requests in
            actualStartTime = startTime
            actualPage = page
            actualRequests = requests
            requestExpectation.fulfill()
            return Request(method: .post, url: Constants.capturedRequestEndpoint)
        }

        let uploadExpectation = expectation(description: "Captured Requests uploaded")
        let uploader = UploaderMock { _ in
            uploadExpectation.fulfill()
        }

        let timerManager = CaptureTimerManagerMock()
        let collector = CapturedRequestCollector(
            logger: Self.logger,
            timerManager: timerManager,
            requestBuilder: requestBuilder,
            uploader: uploader)
        await collector.configure()
        await collector.configure()

        // Start BTTimer
        let expectedPage = Mock.page
        let expectedStartTime = 0.9
        await collector.start(page: expectedPage, startTime: expectedStartTime)

        // Capture Request
        var requestTimer = InternalTimer(logger: Self.logger, intervalProvider: Self.timeIntervalProvider)
        requestTimer.start()
        requestTimer.end()
        let response = Mock.makeCapturedResponse()
        await collector.collect(timer: requestTimer, response: response)

        timerManager.fireTimer()

        try await Task.sleep(nanoseconds: 1.0.nanoseconds)
        wait(for: [requestExpectation, uploadExpectation], timeout: 1.0)

        XCTAssertEqual(actualStartTime, expectedStartTime.milliseconds)
        XCTAssertEqual(actualPage, expectedPage)
        XCTAssertEqual(actualRequests, [Mock.makeCapturedRequest()])
    }
}
