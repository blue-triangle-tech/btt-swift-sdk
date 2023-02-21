//
//  TimerRequestBuilderTests.swift
//
//  Created by Mathew Gacy on 2/17/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class TimerRequestBuilderTests: XCTestCase {
    var timer: BTTimer {
        var timeIntervals: [TimeInterval] = [
            2000,
            1000,
            0
        ]

        let timer = BTTimer(
            page: Mock.page,
            logger: LoggerMock(),
            intervalProvider: { timeIntervals.popLast() ?? 0 },
            performanceMonitor: PerformanceMonitorMock())

        timer.start()
        timer.markInteractive()
        timer.end()

        return timer
    }

    func testBuildRequest() throws {
        let expectedString = Mock.makeTimerRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion,
            sdkVersion: Version.number)

        let errorExpectation = expectation(description: "Unexpected error logged")
        errorExpectation.isInverted = true
        let logger = LoggerMock(onError: { _ in
                errorExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger)

        let actualBody = try sut.builder(Mock.session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        XCTAssertEqual(String(decoding: actualBody, as: UTF8.self), expectedString)
    }

    func testMetrics() throws {
        let expectedKeyValue = "value"

        let errorExpectation = expectation(description: "Unexpected error logged")
        errorExpectation.isInverted = true
        let logger = LoggerMock(onError: { _ in
                errorExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger)

        var session = Mock.session
        session.metrics = ["key": .string(expectedKeyValue)]
        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        let jsonObject = try JSONSerialization.jsonObject(with: actualBody) as! [String: Any]
        let actualMetrics = jsonObject["ECV"] as! [String: String]

        XCTAssertEqual(actualMetrics, ["key": expectedKeyValue])
    }

    func testMetricsExceedingLengthLimitLogged() throws {
        let expectedMessage = "Custom metrics length is 2010 characters; exceeding 1024 results in data loss."
        let expectedKeyValue = String(repeating: "a", count: 2_000)

        var errorMessage: String?
        let errorExpectation = expectation(description: "Error logged")
        let logger = LoggerMock(onError: { message in
            errorMessage = message
            errorExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger)

        var session = Mock.session
        session.metrics = ["key": .string(expectedKeyValue)]
        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        let jsonObject = try JSONSerialization.jsonObject(with: actualBody) as! [String: Any]
        let actualMetrics = jsonObject["ECV"] as! [String: String]

        XCTAssertEqual(actualMetrics, ["key": expectedKeyValue])
        XCTAssertEqual(errorMessage, expectedMessage)
    }

    func testMetricsExceedingSizeLimitDropped() throws {
        let expectedMessage = "Custom metrics encoded size of 4 MB (4,000,016 bytes) exceeds limit of 3 MB (3,000,000 bytes); dropping from timer request."
        let expectedString = Mock.makeTimerRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion,
            sdkVersion: Version.number)

        var errorMessage: String?
        let errorExpectation = expectation(description: "Error logged")
        let logger = LoggerMock(onError: { message in
            errorMessage = message
            errorExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger)

        var session = Mock.session
        session.metrics = ["key": .string(String(repeating: "a", count: 3_000_000))]
        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        XCTAssertEqual(String(decoding: actualBody, as: UTF8.self), expectedString)
        XCTAssertEqual(errorMessage, expectedMessage)
    }
}
