//
//  BTTimerTests.swift
//
//  Created by Mathew Gacy on 10/15/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import XCTest
import Combine
@testable import BlueTriangle

final class BTTimerTests: XCTestCase {

    func testTimerTimes() {
        let expectedStartTime: TimeInterval = 0
        let expectedInteractiveTime: TimeInterval = 1000
        let expectedEndTime: TimeInterval = 2000

        var timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime
        ]

        let timerConfiguration = Mock.makeTimerConfiguration {
            timeIntervals.popLast() ?? 9
        }

        let timerFactory = timerConfiguration.makeTimerFactory(logger: LoggerMock())

        let pageModel = Page(pageName: "MY_PAGE_NAME")
        let timer = timerFactory(pageModel, .main, false)

        timer.start()
        timer.markInteractive()
        timer.end()

        XCTAssertEqual(timer.startTime, expectedStartTime)
        XCTAssertEqual(timer.interactiveTime, expectedInteractiveTime)
        XCTAssertEqual(timer.endTime, expectedEndTime)

        XCTAssertEqual(timer.pageTimeInterval.startTime, expectedStartTime.milliseconds)
        XCTAssertEqual(timer.pageTimeInterval.interactiveTime, expectedInteractiveTime.milliseconds)
        XCTAssertEqual(timer.pageTimeInterval.pageTime,
                       expectedEndTime.milliseconds - expectedStartTime.milliseconds)
    }

    func testTimerTimesWithRepeatedActions() {
        let expectedStartTime: TimeInterval = 0
        let expectedInteractiveTime: TimeInterval = 1000
        let expectedEndTime: TimeInterval = 2000

        var timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime
        ]

        let timerConfiguration = Mock.makeTimerConfiguration {
            timeIntervals.popLast() ?? 9
        }

        let timerFactory = timerConfiguration.makeTimerFactory(logger: LoggerMock())

        let pageModel = Page(pageName: "MY_PAGE_NAME")
        let timer = timerFactory(pageModel, .main, false)
        timer.start()
        timer.start()
        timer.markInteractive()
        timer.start()
        timer.end()
        timer.start()
        timer.end()
        timer.markInteractive()

        XCTAssertEqual(timer.startTime, expectedStartTime)
        XCTAssertEqual(timer.interactiveTime, expectedInteractiveTime)
        XCTAssertEqual(timer.endTime, expectedEndTime)

        XCTAssertEqual(timer.pageTimeInterval.startTime, expectedStartTime.milliseconds)
        XCTAssertEqual(timer.pageTimeInterval.interactiveTime, expectedInteractiveTime.milliseconds)
        XCTAssertEqual(timer.pageTimeInterval.pageTime,
                       expectedEndTime.milliseconds - expectedStartTime.milliseconds)
        timer.end()
    }

    func testTimerStateTransition() {
        let timerConfiguration = Mock.makeTimerConfiguration {
            1000
        }

        let timerFactory = timerConfiguration.makeTimerFactory(logger: LoggerMock())

        let pageModel = Page(pageName: "MY_PAGE_NAME")
        let timer = timerFactory(pageModel, .main, false)

        XCTAssertEqual(timer.state, .initial)
        timer.markInteractive()
        XCTAssertEqual(timer.state, .initial)
        timer.end()
        XCTAssertEqual(timer.state, .initial)

        // -> .start
        timer.start()
        XCTAssertEqual(timer.state, .started)
        timer.start()
        XCTAssertEqual(timer.state, .started)

        // -> .interactive
        timer.markInteractive()
        XCTAssertEqual(timer.state, .interactive)
        timer.markInteractive()
        XCTAssertEqual(timer.state, .interactive)
        timer.start()
        XCTAssertEqual(timer.state, .interactive)

        // -> .ended
        timer.end()
        XCTAssertEqual(timer.state, .ended)
        timer.start()
        XCTAssertEqual(timer.state, .ended)
        timer.markInteractive()
        XCTAssertEqual(timer.state, .ended)
        timer.end()
    }
}
