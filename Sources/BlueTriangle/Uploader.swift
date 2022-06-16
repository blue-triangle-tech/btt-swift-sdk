//
//  Uploader.swift
//
//  Created by Mathew Gacy on 10/25/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

typealias Networking = (Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError>

struct TimerRequestBuilder {
    let builder: (Session, BTTimer, PurchaseConfirmation?) throws -> Request

    static let live = TimerRequestBuilder { session, timer, purchase in
        let model = TimerRequest(session: session,
                                 page: timer.page,
                                 timer: timer.pageTimeInterval,
                                 purchaseConfirmation: purchase,
                                 performanceReport: timer.performanceReport)
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           model: model)
    }
}

final class Uploader: Uploading {
    private let lock = NSLock()

    private let queue: DispatchQueue

    private let logger: Logging

    private let networking: Networking

    private let retryConfiguration: RetryConfiguration<DispatchQueue>

    private var subscriptions = [UUID: AnyCancellable]()

     var subscriptionCount: Int {
         lock.sync { subscriptions.count }
     }

    init(
        queue: DispatchQueue,
        logger: Logging,
        networking: @escaping Networking,
        retryConfiguration: RetryConfiguration<DispatchQueue>
    ) {
        self.queue = queue
        self.logger = logger
        self.networking = networking
        self.retryConfiguration = retryConfiguration
    }

    func send(request: Request) {
        let id = UUID()
        let publisher = networking(request)
            .retry(retryConfiguration, scheduler: queue)
            .subscribe(on: queue)
            .sink(
                receiveCompletion: { [weak self] completion in
                     if case .failure(let error) = completion {
                         self?.logger.error(error.localizedDescription)
                     }
                    self?.removeSubscription(id: id)
                },
                receiveValue: { [weak self] value in
                    self?.logger.info("HTTP Status: \(value.response.statusCode)")
                }
            )

        addSubscription(publisher, id: id)
    }

    private func addSubscription(_ cancellable: AnyCancellable, id: UUID) {
        lock.sync { subscriptions[id] = cancellable }
    }

    private func removeSubscription(id: UUID) {
        lock.sync { subscriptions[id] = nil }
    }
}

// MARK: - Supporting Types
extension Uploader {
    struct RetryConfiguration<S: Scheduler> {
        let maxRetry: UInt
        let initialDelay: S.SchedulerTimeType.Stride
        let delayMultiplier: Double
        let shouldRetry: Publisher.RetryPredicate?
    }

    struct Configuration {
        let queue: DispatchQueue
        let networking: Networking
        let retryConfiguration: RetryConfiguration<DispatchQueue>

        func makeUploader(logger: Logging) -> Uploading {
            Uploader(queue: queue, logger: logger, networking: networking, retryConfiguration: retryConfiguration)
        }

        static let live = Self(
            queue: DispatchQueue(label: "com.bluetriangle.uploader",
                                 qos: .userInitiated,
                                 autoreleaseFrequency: .workItem),
            networking: URLSession.live,
            retryConfiguration: .init(maxRetry: 3,
                                      initialDelay: 10.0,
                                      delayMultiplier: 1.0,
                                      shouldRetry: nil))

    }
}
