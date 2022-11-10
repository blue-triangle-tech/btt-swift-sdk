//
//  NetworkCaptureDelegateTests.swift
//
//  Created by Mathew Gacy on 11/10/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import XCTest

final class NetworkCaptureDelegateTests: XCTestCase {

    static func makeSession() -> URLSession {
        URLSession(
            configuration: .mock,
            delegate: NetworkCaptureSessionDelegate(),
            delegateQueue: nil)
    }

    override func tearDownWithError() throws {
        URLProtocolMock.reset()
    }

    func testMetricsAreCaptured() async throws {
        let metricsExpectation = expectation(description: "Collected session task metrics")
        var metrics: URLSessionTaskMetrics!
        let requestCollector = CapturedRequestCollectorMock(onCollectMetrics: { taskMetrics in
            metrics = taskMetrics
            metricsExpectation.fulfill()
        })

        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            logger: LoggerMock(),
            uploader: UploaderMock(),
            shouldCaptureRequests: true,
            requestCollector: requestCollector
        )

        let resourceURL: URL = "https://example.com"
        let response = Mock.makeHTTPResponse(
            url: resourceURL,
            headerFields: ["Content-Type": "application/json"])

        URLProtocolMock.responseProvider = { _ in
            (Mock.successJSON, response)
        }

        // Start timer for network capture
        _ = BlueTriangle.startTimer(page: Page(pageName: "Example"))

        // Request to capture
        let session = Self.makeSession()

        let responseExpectation = expectation(description: "Received response")
        session.dataTask(with: resourceURL) { data, response, error in
            responseExpectation.fulfill()
        }.resume()

        await waitForExpectations(timeout: 1)

        XCTAssert(metrics.taskInterval.start.timeIntervalSince1970 > 0)
        XCTAssert(metrics.taskInterval.end.timeIntervalSince1970 > 0)
        XCTAssert(metrics.taskInterval.duration > 0)
    }
}
