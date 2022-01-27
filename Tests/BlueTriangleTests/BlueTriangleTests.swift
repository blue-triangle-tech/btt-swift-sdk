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

    static var makePerformanceMonitor: () -> PerformanceMonitoring = {
        PerformanceMonitorMock()
    }

    override class func setUp() {
        super.setUp()
        BlueTriangle.configure { configuration in
            configuration.timerConfiguration = .init(timeIntervalProvider: timeIntervalProvider)
            configuration.uploaderConfiguration = Mock.makeUploaderConfiguration(queue: uploaderQueue) { request in
                onSendRequest(request)
            }
            configuration.performanceMonitorBuilder = PerformanceMonitorBuilder { sampleInterval in
                {
                    makePerformanceMonitor()
                }
            }
        }
        BlueTriangle.prime()
        BlueTriangle.reset()
    }
    
    override func tearDown() {
        Self.onSendRequest = { _ in }
        Self.makePerformanceMonitor = { PerformanceMonitorMock() }
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

        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

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

        BlueTriangle.configure { config in
            Mock.configureBlueTriangle(configuration: config)
            // Internal
            config.requestBuilder = requestBuilder
        }

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

extension BlueTriangleTests {
    @available(iOS 14.0, *)
    func testDisplayLinkPerformanceMonitor() throws {
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

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

        var performanceMonitor: DisplayLinkPerformanceMonitor!
        Self.makePerformanceMonitor = {
            performanceMonitor = DisplayLinkPerformanceMonitor(minimumSampleInterval: 0.1,
                                                               resourceUsage: ResourceUsage.self)
            return performanceMonitor
        }

        BlueTriangle.configure { config in
            Mock.configureBlueTriangle(configuration: config)
            // Internal
            config.requestBuilder = requestBuilder
        }

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
