//
//  TimerRequestBuilderTests.swift
//
//  Created by Mathew Gacy on 2/17/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class TimerRequestBuilderTests: XCTestCase {
   var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

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

        let sut = TimerRequestBuilder.live(logger: logger, encoder: encoder)

        let actualBody = try sut.builder(Mock.session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        XCTAssertEqual(String(decoding: actualBody.base64DecodedData()!, as: UTF8.self), expectedString)
    }

    func testMetrics() throws {
        let value1 = "https://portal.bluetriangletech.com"
        let value2 = 2
        let value3 = "portalv7"
        let value4 = 0
        let value5 = 1188.2999999999884

        let errorExpectation = expectation(description: "Unexpected error logged")
        errorExpectation.isInverted = true
        let logger = LoggerMock(onError: { _ in
                errorExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger, encoder: encoder)

        var session = Mock.session
        session.metrics = [
            "firstVar": .url(URL(string: value1)!),
            "secondVar": .int(value2),
            "thirdVar": .string(value3),
            "fourthVar": .int(value4),
            "fifthVar": .double(value5)
        ]

        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [errorExpectation], timeout: 0.1)

        let jsonString = String(decoding: actualBody, as: UTF8.self)
        let jsonObject = try JSONSerialization.jsonObject(with: actualBody.base64DecodedData()!) as! [String: Any]

        let metricsString = jsonObject["ECV"] as! String
        let metricsObject = try JSONSerialization.jsonObject(with: Data(metricsString.utf8)) as! [String: Any]

        XCTAssertEqual(metricsObject.keys.count, 5)
        XCTAssertEqual(metricsObject["firstVar"] as! String, value1)
        XCTAssertEqual(metricsObject["secondVar"] as! Int, value2)
        XCTAssertEqual(metricsObject["thirdVar"] as! String, value3)
        XCTAssertEqual(metricsObject["fourthVar"] as! Int, value4)
        XCTAssertEqual(metricsObject["fifthVar"] as! Double, value5)
    }

    func testMetricsExceedingLengthLimitLogged() throws {
        let expectedMessage = "Custom metrics length is 2010 characters; exceeding 1024 results in data loss."
        let expectedKeyValue = String(repeating: "a", count: 2_000)

        var logMessge: String?
        let logExpectation = expectation(description: "Warning logged")
        let logger = LoggerMock(onDefault: { message in
            logMessge = message
            logExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger, encoder: encoder)

        var session = Mock.session
        session.metrics = ["key": .string(expectedKeyValue)]
        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [logExpectation], timeout: 0.1)

        let jsonObject = try JSONSerialization.jsonObject(with: actualBody.base64DecodedData()!) as! [String: Any]
        let actualMetrics = jsonObject["ECV"] as! String

        XCTAssertEqual(actualMetrics, "{\"key\":\"\(expectedKeyValue)\"}")
        XCTAssertEqual(logMessge, expectedMessage)
    }

    func testMetricsExceedingSizeLimitDropped() throws {
        let expectedMessage = "Custom metrics encoded size of 4 MB (4,000,016 bytes) exceeds limit of 3 MB (3,000,000 bytes); dropping from timer request."
        let expectedString = Mock.makeTimerRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion,
            sdkVersion: Version.number)

        var logMessge: String?
        let logExpectation = expectation(description: "Warning logged")
        let logger = LoggerMock(onDefault: { message in
            logMessge = message
            logExpectation.fulfill()
        })

        let sut = TimerRequestBuilder.live(logger: logger, encoder: encoder)

        var session = Mock.session
        session.metrics = ["key": .string(String(repeating: "a", count: 3_000_000))]
        let actualBody = try sut.builder(session, timer, nil).body!
        wait(for: [logExpectation], timeout: 0.1)

        XCTAssertEqual(String(decoding: actualBody.base64DecodedData()!, as: UTF8.self), expectedString)
        XCTAssertEqual(logMessge, expectedMessage)
    }
}
