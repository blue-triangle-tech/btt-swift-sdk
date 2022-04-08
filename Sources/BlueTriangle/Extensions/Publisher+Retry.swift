//
//  Publisher+Retry.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

extension Publisher {

    typealias RetryPredicate = (Error) -> Bool

    // Adapted from: https://stackoverflow.com/a/66916229
    func retry<S: Scheduler>(
        retries: UInt,
        initialDelay: S.SchedulerTimeType.Stride,
        delayMultiplier: Double,
        shouldRetry: RetryPredicate? = nil,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> {
        retry(1,
              retries: retries,
              initialDelay: initialDelay,
              delayMultiplier: delayMultiplier,
              shouldRetry: shouldRetry,
              scheduler: scheduler)
    }

    fileprivate func retry<S: Scheduler>(
        _ currentAttempt: UInt,
        retries: UInt,
        initialDelay: S.SchedulerTimeType.Stride,
        delayMultiplier: Double,
        shouldRetry: RetryPredicate? = nil,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> {
        guard currentAttempt > 0 else { return Empty<Output, Failure>().eraseToAnyPublisher() }

        let delay = Self.calculateDelay(currentAttempt: currentAttempt,
                                        initialDelay: initialDelay,
                                        delayMultiplier: delayMultiplier,
                                        scheduler: scheduler)

        return self.catch { error -> AnyPublisher<Output, Failure> in
            guard currentAttempt <= retries else {
                return Fail(error: error).eraseToAnyPublisher()
            }

            if let shouldRetry = shouldRetry, shouldRetry(error) == false {
                return Fail(error: error).eraseToAnyPublisher()
            }

            guard delay != .zero else {
                return retry(currentAttempt + 1,
                             retries: retries,
                             initialDelay: initialDelay,
                             delayMultiplier: delayMultiplier,
                             shouldRetry: shouldRetry,
                             scheduler: scheduler)
                    .eraseToAnyPublisher()
            }

            return Just(())
                .setFailureType(to: Failure.self)
                .delay(for: delay, scheduler: scheduler)
                .flatMap { _ in
                    retry(currentAttempt + 1, retries: retries, initialDelay: initialDelay,
                          delayMultiplier: delayMultiplier, shouldRetry: shouldRetry, scheduler: scheduler)
                }
                .eraseToAnyPublisher()
        }
            .eraseToAnyPublisher()
    }

    private static func calculateDelay<S: Scheduler>(
        currentAttempt: UInt,
        initialDelay: S.SchedulerTimeType.Stride,
        delayMultiplier: Double,
        scheduler: S
    ) -> S.SchedulerTimeType.Stride {
        currentAttempt == 1
        ? initialDelay
        : initialDelay * S.SchedulerTimeType.Stride.seconds(pow(1 + delayMultiplier, Double(currentAttempt - 1)))
    }
}

// MARK: - Publisher+RetryConfiguration
extension Publisher {
    func retry<S: Scheduler>(
        _ configuration: Uploader.RetryConfiguration<S>,
        scheduler: S
    ) -> AnyPublisher<Output, Failure> {
        retry(retries: configuration.maxRetry,
              initialDelay: configuration.initialDelay,
              delayMultiplier: configuration.delayMultiplier,
              shouldRetry: configuration.shouldRetry,
              scheduler: scheduler)
    }
}
