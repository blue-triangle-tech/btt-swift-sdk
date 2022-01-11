import XCTest
import Combine
@testable import BlueTriangle

final class BlueTriangleTests: XCTestCase {

    static var uploaderQueue: DispatchQueue = Mock.uploaderQueue
    static var onSendRequest: (Request) -> Void = { _ in }

    override class func setUp() {
        super.setUp()
        BlueTriangle.configure { configuration in
            configuration.uploaderConfiguration = Mock.makeUploaderConfiguration(queue: uploaderQueue) { request in
                onSendRequest(request)
            }
        }
        BlueTriangle.prime()
        BlueTriangle.reset()
    }
    
    override func tearDown() {
        Self.onSendRequest = { _ in }
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

        var timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime,
        ]
        let timerConfiguration = Mock.makeTimerConfiguration { timeIntervals.popLast() ?? 0 }

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
            config.timerConfiguration = timerConfiguration
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
