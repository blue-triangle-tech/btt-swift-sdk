//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CapturedRequestCollector: CapturedRequestCollecting {
    private var storage: Timeline<RequestSpan>
    private let queue: DispatchQueue
    private let logger: Logging
    private var timerManager: CaptureTimerManaging
    private let timeIntervalProvider: () -> TimeInterval
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private var spanStartTime: TimeInterval?

    convenience init(
        queue: DispatchQueue,
        logger: Logging,
        timerManager: CaptureTimerManaging,
        timeIntervalProvider: @escaping () -> TimeInterval,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading
    ) {
        self.init(
            storage: Timeline<RequestSpan>(intervalProvider: timeIntervalProvider),
            queue: queue,
            logger: logger,
            timerManager: timerManager,
            timeIntervalProvider: timeIntervalProvider,
            requestBuilder: requestBuilder,
            uploader: uploader)
    }

    init(
        storage: Timeline<RequestSpan>,
        queue: DispatchQueue,
        logger: Logging,
        timerManager: CaptureTimerManaging,
        timeIntervalProvider: @escaping () -> TimeInterval,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading
    ) {
        self.storage = storage
        self.queue = queue
        self.logger = logger
        self.timerManager = timerManager
        self.timeIntervalProvider = timeIntervalProvider
        self.requestBuilder = requestBuilder
        self.uploader = uploader
        self.timerManager.handler = { [weak self] in
            self?.batchCapturedRequests()
        }
    }

    func start(page: Page) {
        self.spanStartTime = self.timeIntervalProvider()
        self.timerManager.start()
        queue.sync {
            let currentSpan = self.storage.batchCurrentRequests()
            let poppedSpan = self.storage.insert(.init(page))

            self.queue.async {
                if let current = currentSpan {
                    self.upload(current)
                }
                if let popped = poppedSpan, popped.value.isNotEmpty {
                    self.upload(popped)
                }
            }
        }
    }

    func makeTimer() -> InternalTimer? {
        guard let spanStartTime = spanStartTime else {
            logger.error("Unable to make timer before first call to `start(page:)`.")
            return nil
        }
        return InternalTimer(logger: logger, offset: spanStartTime, intervalProvider: timeIntervalProvider)
    }

    func collect(timer: InternalTimer, data: Data?, response: URLResponse?) {
        let capturedRequest = CapturedRequest(timer: timer, response: response)
        queue.sync {
            self.storage.updateValue(for: timer.startTime) { span in
                span.insert(capturedRequest)
            }
        }
    }

    /// Upload current requests if there are any.
    ///
    /// - Important: This method mutates `storage` and is not thread-safe.
    ///   You must call it from `queue` .
    private func batchCapturedRequests() {
        if let currentSpan = self.storage.batchCurrentRequests() {
            self.queue.async {
                self.upload(currentSpan)
            }
        }
    }

    private func upload(_ span: (TimeInterval, TimeInterval, RequestSpan)) {
        do {
            let request = try requestBuilder.build(span.0.milliseconds, span.1.milliseconds, span.2)
            uploader.send(request: request)
        } catch {
            logger.error("Error building request: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types
extension CapturedRequestCollector {
    struct Configuration {
        let queue: DispatchQueue
        let timeIntervalProvider: () -> TimeInterval
        let timerManagingProvider: (NetworkCaptureConfiguration) -> CaptureTimerManaging

        func makeRequestCollector(
            logger: Logging,
            networkCaptureConfiguration: NetworkCaptureConfiguration,
            requestBuilder: CapturedRequestBuilder,
            uploader: Uploading
        ) -> CapturedRequestCollector {
            let timerManager = timerManagingProvider(networkCaptureConfiguration)
            return CapturedRequestCollector(queue: queue,
                                            logger: logger,
                                            timerManager: timerManager,
                                            timeIntervalProvider: timeIntervalProvider,
                                            requestBuilder: requestBuilder,
                                            uploader: uploader)
        }

        static var live: Self {
            let queue = DispatchQueue(label: "com.bluetriangle.network-capture",
                                      qos: .utility,
                                      autoreleaseFrequency: .workItem)
            return Configuration(queue: queue, timeIntervalProvider: { Date().timeIntervalSince1970 }) { configuration in
                CaptureTimerManager(queue: queue, configuration: configuration)
            }
        }
    }
}
