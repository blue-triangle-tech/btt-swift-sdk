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

    func testInsert() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        let requestSpan = RequestSpan(Mock.page)
        timeline.insert(requestSpan)
        XCTAssertEqual(timeline.current, requestSpan)
    }

    func testCount() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        let requestSpan = RequestSpan(Mock.page)
        XCTAssertEqual(timeline.count, 0)
        timeline.insert(requestSpan)
        XCTAssertEqual(timeline.count, 1)
    }

    func testValueForIfEmpty() throws {
        let timeline = Timeline<RequestSpan>(capacity: 5)
        let value = timeline.value(for: 1000)
        XCTAssertNil(value)
    }

    func testValueForBefore() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        timeline.insert(RequestSpan(Mock.page))
        let value = timeline.value(for: 999)
        XCTAssertNil(value)
    }

    func testValueFor() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        timeline.insert(RequestSpan(Mock.page))
        let value = timeline.value(for: 1000)!
        XCTAssertEqual(value.page, Mock.page)
    }

    func testValueForAfter() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        timeline.insert(RequestSpan(Mock.page))
        let value = timeline.value(for: 2000)!
        XCTAssertEqual(value.page, Mock.page)
    }

    func testCapacity() throws {
        let capacity = 4
        var timeline = Timeline<RequestSpan>(capacity: capacity, intervalProvider: Self.timeIntervalProvider)
        // Insert spans to reach capacity
        Array(0...3).map { RequestSpan(Page(pageName: pageNames[$0])) }.forEach { timeline.insert($0) }

        // Insert additional span
        let popped = timeline.insert(RequestSpan(Page(pageName: pageNames.last!)))!
        XCTAssertEqual(timeline.count, capacity)
        XCTAssertEqual(popped.page.pageName, pageNames.first!)
    }

    func testUpdateValue() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        let page1 = Page(pageName: pageNames[0])
        timeline.insert(RequestSpan(page1))
        let page2 = Page(pageName: pageNames[1])
        timeline.insert(RequestSpan(page2))

        timeline.updateValue(for: 1050) { $0.insert(Mock.capturedRequest) }
        let updated = timeline.pop()!

        XCTAssertEqual(updated.page, page1)
        XCTAssertEqual(updated.requests, [Mock.capturedRequest])
    }

    func testUpdateCurrent() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        timeline.insert(RequestSpan(Mock.page))

        timeline.updateCurrent { span in
            span.insert(Mock.capturedRequest)
        }

        let updated = timeline.current!
        XCTAssertEqual(updated.page, Mock.page)
        XCTAssertEqual(updated.requests, [Mock.capturedRequest])
    }

    func testPop() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        pageNames.map { RequestSpan(Page(pageName: $0)) }.forEach { timeline.insert($0) }

        let firstPopped = timeline.pop()
        XCTAssertEqual(firstPopped?.page.pageName, "page_1")
        XCTAssertEqual(timeline.count, 4)

        for _ in 0..<4 { timeline.pop() }

        XCTAssertEqual(timeline.count, 0)
        XCTAssertNil(timeline.current)
    }

    func testNodeFor() throws {
        var timeline = Timeline<RequestSpan>(capacity: 5, intervalProvider: Self.timeIntervalProvider)
        pageNames.map { RequestSpan(Page(pageName: $0)) }.forEach { timeline.insert($0) }

        let nodeBeforeHead = timeline.value(for: 999)
        XCTAssertNil(nodeBeforeHead)

        let nodeAtHead = timeline.value(for: 1000)
        XCTAssertEqual(nodeAtHead?.page.pageName, "page_1")

        let nodeAfterHead = timeline.value(for: 1001)
        XCTAssertEqual(nodeAfterHead?.page.pageName, "page_1")

        let nodeBeforeTail = timeline.value(for: 4999)
        XCTAssertEqual(nodeBeforeTail?.page.pageName, "page_4")

        let nodeAtTail = timeline.value(for: 5001)
        XCTAssertEqual(nodeAtTail?.page.pageName, "page_5")

        let nodeAfterTail = timeline.value(for: 5001)
        XCTAssertEqual(nodeAfterTail?.page.pageName, "page_5")
    }
}

// MARK: - Performance
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
