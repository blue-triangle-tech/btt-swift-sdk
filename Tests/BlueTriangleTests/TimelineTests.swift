//
//  TimelineTests.swift
//
//  Created by Mathe  on 3/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class TimelineTests: XCTestCase {
    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }

    let timeIntervals: [TimeInterval] = [5.0, 4.0, 3.0, 2.0, 1.0]
    let pageNames: [String] = ["page_1", "page_2", "page_3", "page_4", "page_5"]

    override func setUp() {
        Self.timeIntervals = timeIntervals
    }
}

extension TimelineTests {
    /// MacBook Pro (13-inch, M1, 2020) - macOS 11.6.4 - 1.029 sec for 100_000 pages
    /// average: 1.029
    /// relative standard deviation: 1.817%
    /// values: [1.082314, 1.025249, 1.019529, 1.026180, 1.030145, 1.036990, 1.018182, 1.014735, 1.017959, 1.022860]
    func testPerformance() throws {
        let totalPageCount: Int = 100_000
        let currentTimeOffsets: [Millisecond] = [-6543, 100, 200, 300, 400, -1234, -2345, -3456, 500, -4567]

        var currentTime: TimeInterval = 0.0
        var pageCount: Int = 0

        func makePage() -> Page {
            pageCount += 1
            return Page(pageName: "Page \(pageCount)")
        }

        func makeCapturedRequest(offset: Millisecond) -> CapturedRequest {
            var request = Mock.capturedRequest
            request.startTime = currentTime.milliseconds + offset
            return request
        }

        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: {
            currentTime += 1
            return currentTime
        })

        self.measure {
            for _ in 0..<totalPageCount {
                let _ = timeline.insert(.init(makePage()))

                for offset in currentTimeOffsets {
                    let startTime = currentTime.milliseconds + offset
                    timeline.updateValue(for: startTime) { span in
                        let request = makeCapturedRequest(offset: offset)
                        span.insert(request)
                    }
                }

                var batched: [CapturedRequest]?
                timeline.updateCurrent { span in
                    batched = span.batchRequests()
                }
                let _ = batched
            }
        }
    }
}
