//
//  UploaderTests.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import XCTest
import Combine
@testable import BlueTriangle

final class UploaderTests: XCTestCase {

    func testRetryFailure() {
        var cancellables = Set<AnyCancellable>()

        let retryAttempts = 3

        var requestCount = 0
        let dataTaskPublisher: AnyPublisher<(data: Data, response: URLResponse), Error> = Deferred {
            Future { promise in
                requestCount += 1
                promise(.failure(TestError()))
            }
        }.eraseToAnyPublisher()

        let failureExpectation = self.expectation(description: "Requests failed")
        dataTaskPublisher
            .retry(retries: UInt(retryAttempts),
                   initialDelay: 1.0,
                   delayMultiplier: 1.0,
                   shouldRetry: nil,
                   scheduler: ImmediateScheduler.shared)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    XCTFail("Unexpected success")
                case .failure:
                    failureExpectation.fulfill()
                }
            }, receiveValue: { value in
                XCTFail("Unexpected value")
            })
            .store(in: &cancellables)

        XCTAssertEqual(requestCount, retryAttempts + 1)
        waitForExpectations(timeout: 1.0)
    }

    func testRetrySuccess() {
        var cancellables = Set<AnyCancellable>()

        let retryAttempts = 3

        var requestCount = 0

        let dataTaskPublisher: AnyPublisher<(data: Data, response: URLResponse), Error> = Deferred {
            Future { promise in
                requestCount += 1
                promise(.success(Self.successResponse))
            }
        }.eraseToAnyPublisher()

        let successExpectation = self.expectation(description: "Request succeeded")
        let valueExpectation = self.expectation(description: "Received value")
        dataTaskPublisher
            .retry(retries: UInt(retryAttempts),
                   initialDelay: 1.0,
                   delayMultiplier: 1.0,
                   shouldRetry: nil,
                   scheduler: ImmediateScheduler.shared)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    successExpectation.fulfill()
                case .failure:
                    XCTFail("Unexpected failure")
                }
            }, receiveValue: { value in
                valueExpectation.fulfill()
            })
            .store(in: &cancellables)

        XCTAssertEqual(requestCount, 1)
        waitForExpectations(timeout: 1.0)
    }

    func testRetryFailureThenSuccess() {
        var cancellables = Set<AnyCancellable>()

        let retryAttempts = 3

        var errorCount = 0
        var requestCount = 0
        let dataTaskPublisher: AnyPublisher<(data: Data, response: URLResponse), Error> = Deferred {
            Future { promise in
                requestCount += 1
                if requestCount < 3 {
                    errorCount += 1
                    promise(.failure(TestError()))
                } else {
                    promise(.success(Self.successResponse))
                }
            }
        }.eraseToAnyPublisher()

        let successExpectation = self.expectation(description: "Request succeeded")
        let valueExpectation = self.expectation(description: "Received value")
        dataTaskPublisher
            .retry(retries: UInt(retryAttempts),
                   initialDelay: 1.0,
                   delayMultiplier: 1.0,
                   shouldRetry: nil,
                   scheduler: ImmediateScheduler.shared)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    successExpectation.fulfill()
                case .failure:
                    XCTFail("Unexpected failure")
                }
            }, receiveValue: { value in
                valueExpectation.fulfill()
            })
            .store(in: &cancellables)

        XCTAssertEqual(errorCount, 2)
        XCTAssertEqual(requestCount, 3)
        waitForExpectations(timeout: 1.0)
    }
}

// MARK: - Helpers
extension BTUploaderTests {
    typealias Response = (data: Data, response: HTTPURLResponse)

    struct TestError: Error {}

    static let errorJSON = """
          {
            "error": "someError"
          }
          """.data(using: .utf8)!

    static let successJSON = """
          {
            "foo": "bar"
          }
          """.data(using: .utf8)!

    static func makeHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: "https://example.com",
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: nil)!
    }

    static var successResponse = Response(
        data: successJSON,
        response: makeHTTPResponse(statusCode: 200)
    )

    static var errorResponse = Response(
        data: errorJSON,
        response: makeHTTPResponse(statusCode: 400)
    )
}
