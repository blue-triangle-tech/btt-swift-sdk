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
                promise(.failure(Mock.TestError()))
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
                promise(.success(Mock.urlSuccessResponse))
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
                    promise(.failure(Mock.TestError()))
                } else {
                    promise(.success(Mock.urlSuccessResponse))
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

    func testUploaderSubscriptionRemoval() throws {
        let requestCount: Int = 10_000
        let expectation = self.expectation(description: "Requests finished")

        var currentRequestCount = 0
        let networking: Networking = { request in
            Deferred {
                Future { promise in
                    currentRequestCount += 1
                    promise(.success(Mock.successResponse))
                }
            }.eraseToAnyPublisher()
        }

        var responseCount = 0
        let log: (String) -> Void = { _ in
            responseCount += 1
            if responseCount == requestCount * 2 {
                expectation.fulfill()
            }
        }

        let uploaderQueue = Mock.uploaderQueue
        let uploader = Uploader(queue: uploaderQueue, log: log, networking: networking, retryConfiguration: Mock.retryConfiguration)

        let group = DispatchGroup()
        DispatchQueue.global().async(group: group) {
            for _ in 0 ..< requestCount {
                uploader.send(request: Mock.request)
            }
        }

        DispatchQueue.global().async(group: group) {
            for _ in 0 ..< requestCount {
                uploader.send(request: Mock.request)
            }
        }

        group.notify(queue: .main) {
            print("SubscriptionCount: \(uploader.subscriptionCount)")
            XCTAssert(uploader.subscriptionCount > requestCount)
        }

        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(currentRequestCount, requestCount * 2)
        XCTAssertEqual(responseCount, requestCount * 2)

        let otherExpectation = self.expectation(description: "Allow completion")
        otherExpectation.isInverted = true
        wait(for: [otherExpectation], timeout: 2.0)

        XCTAssertEqual(uploader.subscriptionCount, 0)
    }
}
