//
//  BlueTriangleTests.swift
//
//  Created by Mathew Gacy on 1/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
import Combine
@testable import BlueTriangle

final class BlueTriangleTests: XCTestCase {

    static var uploaderQueue: DispatchQueue = Mock.uploaderQueue
    static var onSendRequest: (Request) -> Void = { _ in }

    static var timeIntervals: [TimeInterval] = []
    static var timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }
    static var logger: LoggerMock = .init()
    static var performanceMonitor: PerformanceMonitoring = PerformanceMonitorMock()

    override class func setUp() {
        super.setUp()
        BlueTriangle.configure { configuration in
            configuration.makeLogger = {
                logger
            }
            configuration.timerConfiguration = .init(timeIntervalProvider: timeIntervalProvider)
            configuration.uploaderConfiguration = Mock.makeUploaderConfiguration(queue: uploaderQueue) { request in
                onSendRequest(request)
            }
            configuration.performanceMonitorBuilder = PerformanceMonitorBuilder { sampleInterval in
                {
                    performanceMonitor
                }
            }
        }
        BlueTriangle.prime()
        BlueTriangle.reset()
    }
    
    override func tearDown() {
        Self.onSendRequest = { _ in }
        Self.timeIntervals = []
        BlueTriangle.reset()
        super.tearDown()
    }

    func testOSInfo() {
        let os = Device.os
        let osVersion = Device.osVersion

        #if os(iOS)
        XCTAssertEqual(os, "iOS")
        #elseif os(tvOS)
        XCTAssertEqual(os, "tvOS")
        #elseif os(watchOS)
        XCTAssertEqual(os, "watchOS")
        #elseif os(macOS)
        XCTAssertEqual(os, "macOS")
        #endif

        XCTAssertFalse(osVersion.isEmpty)
    }

    func testFullTimer() throws {
        let expectedStartTime: TimeInterval = 0
        let expectedInteractiveTime: TimeInterval = 1000
        let expectedEndTime: TimeInterval = 2000

        Self.timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime,
        ]

        // Performance Monitor
        let performanceStartExpectation = expectation(description: "Performance monitoring started")
        let performanceEndExpectation = expectation(description: "Performance monitoring ended")
        let expectedReport = PerformanceReport(minCPU: 1.0,
                                               maxCPU: 100.0,
                                               avgCPU: 50.0,
                                               minMemory: 10000000,
                                               maxMemory: 100000000,
                                               avgMemory: 50000000)
        let performanceMonitor = PerformanceMonitorMock(report: expectedReport,
                                                        onStart: { performanceStartExpectation.fulfill() },
                                                        onEnd: { performanceEndExpectation.fulfill() })

        // Timer
        let timerFactory: (Page) -> BTTimer = { page in
            BTTimer(page: page,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    performanceMonitor: performanceMonitor)
        }

        // Request Builder
        var finishedTimer: BTTimer!
        let requestBuilder = RequestBuilder { session, timer, purchaseConfirmation in
            finishedTimer = timer
            let model = TimerRequest(session: session,
                                     page: timer.page,
                                     timer: timer.pageTimeInterval,
                                     purchaseConfirmation: purchaseConfirmation,
                                     performanceReport: nil)

            return try Request(method: .post,
                               url: Constants.timerEndpoint,
                               headers: nil,
                               model: model)
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // Configure
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = requestBuilder
        BlueTriangle.reconfigure(configuration: configuration,
                                 timerFactory: timerFactory)

        let timer = BlueTriangle.startTimer(page: Mock.page)
        timer.markInteractive()
        BlueTriangle.endTimer(timer)

        XCTAssertNotNil(finishedTimer)
        XCTAssertEqual(finishedTimer.startTime, expectedStartTime)
        XCTAssertEqual(finishedTimer.interactiveTime, expectedInteractiveTime)
        XCTAssertEqual(finishedTimer.endTime, expectedEndTime)

        waitForExpectations(timeout: 5.0)

        let base64Decoded = Data(base64Encoded: request.body!)!
        let requestString = String(data: base64Decoded, encoding: .utf8)
        let expectedString = Mock.makeRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion)

        XCTAssertEqual(requestString, expectedString)
    }
}

#if os(iOS) || os(tvOS)
extension BlueTriangleTests {
    @available(iOS 14.0, *)
    func testDisplayLinkPerformanceMonitor() throws {
        let performanceMonitor = DisplayLinkPerformanceMonitor(minimumSampleInterval: 0.1,
                                                               resourceUsage: ResourceUsage.self)

        // Timer
        let timerFactory: (Page) -> BTTimer = { page in
            BTTimer(page: page,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    performanceMonitor: performanceMonitor)
        }

        // Request Builder
        var finishedTimer: BTTimer!
        let requestBuilder = RequestBuilder { session, timer, purchaseConfirmation in
            finishedTimer = timer
            let model = TimerRequest(session: session,
                                     page: timer.page,
                                     timer: timer.pageTimeInterval,
                                     purchaseConfirmation: purchaseConfirmation,
                                     performanceReport: timer.performanceReport)

            return try Request(method: .post,
                               url: Constants.timerEndpoint,
                               headers: nil,
                               model: model)
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // Configure
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = requestBuilder
        BlueTriangle.reconfigure(configuration: configuration,
                                 timerFactory: timerFactory)

        // ViewController
        let imageSize: CGSize = .init(width: 150, height: 150)
        let delayStragegy: DelayGenerator.Strategy = .random((mean: 1, variation: 0.5))
        let networkClient: NetworkClientMock = .makeClient(delayStrategy: delayStragegy,
                                                           imageSize: imageSize)
        let viewController = CollectionViewController(networkClient: networkClient)
        viewController.viewDidLoad()

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(finishedTimer)
        print(performanceMonitor.measurements)
        // ...
    }
}
#endif

