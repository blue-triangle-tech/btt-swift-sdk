//
//  CaptureTimerManagerTests.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

class CaptureTimerManagerTests: XCTestCase {
    static let timerLeeway = DispatchTimeInterval.nanoseconds(1)
    static let configuration = NetworkCaptureConfiguration(
        spanCount: 2,
        initialSpanDuration: 0.1,
        subsequentSpanDuration: 0.1)

    func testStartFromInactive() throws {
        let manager = CaptureTimerManager(
            queue: Mock.uploaderQueue,
            configuration: Self.configuration,
            timerLeeway: Self.timerLeeway)

        let expectedFireCount = Self.configuration.spanCount
        let fireExpectation = expectation(description: "Timer fired twice.")

        let additionalFireExpectation = expectation(description: "Fire count exceeded spanCount.")
        additionalFireExpectation.isInverted = true

        var fireCount: Int = 0
        manager.handler = {
            fireCount += 1
            if fireCount == expectedFireCount {
                fireExpectation.fulfill()
            } else if fireCount > expectedFireCount {
                additionalFireExpectation.fulfill()
            }
        }
        manager.start()

        waitForExpectations(timeout: 1)
        XCTAssertEqual(manager.state, .inactive)
    }

    func testStartFromActive() throws {
        let queue = Mock.uploaderQueue
        let configuration = NetworkCaptureConfiguration(
            spanCount: 2,
            initialSpanDuration: 0.3,
            subsequentSpanDuration: 0.1)

        let manager = CaptureTimerManager(
            queue: queue,
            configuration: configuration,
            timerLeeway: Self.timerLeeway)


        let excessiveFireExpectation = expectation(description: "Fire count exceeded spanCount.")
        excessiveFireExpectation.isInverted = true

        var fireCount: Int = 0
        manager.handler = {
            fireCount += 1
            if fireCount > 3 {
                excessiveFireExpectation.fulfill()
            }
        }

        manager.start()

        queue.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(manager.state, .active(span: 1))
            XCTAssertEqual(fireCount, 0)
            manager.start()
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(fireCount, 2)
    }

    func testCancelFromActive() throws {
        let queue = Mock.uploaderQueue
        let configuration = NetworkCaptureConfiguration(
            spanCount: 10,
            initialSpanDuration: 0.2,
            subsequentSpanDuration: 0.1)

        let manager = CaptureTimerManager(
            queue: queue,
            configuration: configuration,
            timerLeeway: Self.timerLeeway)


        let fireExpectation = expectation(description: "Timer fired.")
        fireExpectation.isInverted = true
        manager.handler = {
            fireExpectation.fulfill()
        }

        manager.start()

        queue.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(manager.state, .active(span: 1))
            manager.cancel()
            XCTAssertEqual(manager.state, .inactive)
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(manager.state, .inactive)
    }
}
