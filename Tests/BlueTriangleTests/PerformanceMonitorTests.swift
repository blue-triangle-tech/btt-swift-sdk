//
//  PerformanceMonitorTests.swift
//
//  Created by Mathew Gacy on 1/13/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
import Combine
@testable import BlueTriangle

final class PerformanceMonitorTests: XCTestCase {

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

    @available(iOS 14.0, *)
    func test1() throws {
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

        // ViewController
        let imageSize: CGSize = .init(width: 150, height: 150)
        let delayStragegy: DelayGenerator.Strategy = .random((mean: 1, variation: 0.5))
        let networkClient: NetworkClientMock = .makeClient(delayStrategy: delayStragegy,
                                                           imageSize: imageSize)
        let viewController = CollectionViewController(networkClient: networkClient)
        viewController.viewDidLoad()

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(finishedTimer)
        print(finishedTimer!)
        // ...
    }
}
