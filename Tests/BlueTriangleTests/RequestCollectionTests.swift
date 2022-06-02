//
//  RequestCollectionTests.swift
//
//  Created by Mathew Gacy on 5/29/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest
@testable import BlueTriangle

final class RequestCollectionTests: XCTestCase {
    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
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

    func testInsert() throws {
        var collection = RequestCollection(page: Mock.page, startTime: 900)

        var timer = InternalTimer(logger: LoggerMock(), intervalProvider: Self.timeIntervalProvider)
        timer.start()
        timer.end()

        collection.insert(timer: timer, response: Mock.makeCapturedResponse())

        XCTAssertEqual(collection.requests, [Mock.makeCapturedRequest(startTime: 100, endTime: 200)])
    }

    func testBatchRequests() throws {
        let expected = [Mock.makeCapturedRequest()]

        var collection = RequestCollection(page: Mock.page, startTime: 1000, requests: expected)
        let actual = collection.batchRequests()

        XCTAssertEqual(actual, expected)
        XCTAssertEqual(collection.requests, [])
    }

    func testEmptyBatchRequests() {
        var collection = RequestCollection(page: Mock.page, startTime: 1000, requests: [])

        let actual = collection.batchRequests()

        XCTAssertEqual(actual, nil)
        XCTAssertEqual(collection.requests, [])
    }
}
