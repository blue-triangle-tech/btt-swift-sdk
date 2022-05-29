//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

actor CapturedRequestCollector: CapturedRequestCollecting {
    private let logger: Logging
    private var timerManager: CaptureTimerManaging
    private let timeIntervalProvider: () -> TimeInterval
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private var requestCollection: RequestCollection?
    private(set) var hasBeenConfigured: Bool = false

    init(
        logger: Logging,
        timerManager: CaptureTimerManaging,
        timeIntervalProvider: @escaping () -> TimeInterval,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading
    ) {
        self.logger = logger
        self.timerManager = timerManager
        self.timeIntervalProvider = timeIntervalProvider
        self.requestBuilder = requestBuilder
        self.uploader = uploader
    }

    func configure() {
        guard !hasBeenConfigured else { return }
        timerManager.handler = { [weak self] in
            self?.batchRequests()
        }
        hasBeenConfigured = true
    }

    deinit {
        timerManager.cancel()
    }

    func start(page: Page, startTime: TimeInterval) {
        timerManager.cancel()
        let previousCollection = requestCollection
        requestCollection = RequestCollection(page: page, startTime: startTime.milliseconds)
        timerManager.start()

        if let collection = previousCollection, collection.isNotEmpty {
            upload(startTime: collection.startTime, page: collection.page, requests: collection.requests)
        }
    }

    func collect(timer: InternalTimer, response: URLResponse?) {
        requestCollection?.insert(timer: timer, response: response)
    }

    // Use `nonisolated` to enable capture by timerManager handler.
    nonisolated private func batchRequests() {
        Task {
            await self.batchCapturedRequests()
        }
    }

    private func batchCapturedRequests() {
        guard let requests = requestCollection?.batchRequests(), let timer = requestCollection else {
            return
        }

        upload(startTime: timer.startTime, page: timer.page, requests: requests)
    }

    private func upload(startTime: Millisecond, page: Page, requests: [CapturedRequest]) {
        Task.detached(priority: .background) {
            do {
                let request = try self.requestBuilder.build(startTime, page, requests)
                self.uploader.send(request: request)
            } catch {
                self.logger.error("Error building request: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Types
extension CapturedRequestCollector {
    struct Configuration {
        let timeIntervalProvider: () -> TimeInterval
        let timerManagingProvider: (NetworkCaptureConfiguration) -> CaptureTimerManaging

        func makeRequestCollector(
            logger: Logging,
            networkCaptureConfiguration: NetworkCaptureConfiguration,
            requestBuilder: CapturedRequestBuilder,
            uploader: Uploading
        ) -> CapturedRequestCollector {
            let timerManager = timerManagingProvider(networkCaptureConfiguration)
            return CapturedRequestCollector(logger: logger,
                                                 timerManager: timerManager,
                                                 timeIntervalProvider: timeIntervalProvider,
                                                 requestBuilder: requestBuilder,
                                                 uploader: uploader)
        }

        static var live: Self {
            return Configuration(timeIntervalProvider: { Date().timeIntervalSince1970 }) { configuration in
                CaptureTimerManager(configuration: configuration)
            }
        }
    }
}
