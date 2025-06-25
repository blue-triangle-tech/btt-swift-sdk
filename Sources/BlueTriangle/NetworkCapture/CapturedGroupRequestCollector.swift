//
//  CapturedGroupRequestCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/06/25.
//


import Foundation

actor CapturedGroupRequestCollector: CapturedGroupRequestCollecting {
    private let logger: Logging
    private var timerManager: CaptureTimerManaging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private let uploadTaskPriority: TaskPriority
    private var requestCollection: GroupRequestCollection?
    private(set) var hasBeenConfigured: Bool = false

    init(
        logger: Logging,
        timerManager: CaptureTimerManaging,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading,
        uploadTaskPriority: TaskPriority = .utility
    ) {
        self.logger = logger
        self.timerManager = timerManager
        self.requestBuilder = requestBuilder
        self.uploader = uploader
        self.uploadTaskPriority = uploadTaskPriority
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
        requestCollection = GroupRequestCollection(page: page, startTime: startTime.milliseconds)
        timerManager.start()
        
        if let collection = previousCollection, collection.isNotEmpty {
            upload(startTime: collection.startTime, page: collection.page, requests: collection.requests)
        }
    }
    
    func collect(pageName : String, startTime: Millisecond){
        requestCollection?.updateNetworkCapture(pageName: pageName, startTime: startTime)
    }

    func collect(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, response: CustomPageResponse){
        requestCollection?.insert(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, response: response)
    }

    // Use `nonisolated` to enable capture by timerManager handler.
    nonisolated private func batchRequests() {
        Task {
            await self.batchCapturedRequests()
        }
    }

    private func batchCapturedRequests() {
        guard let requests = requestCollection?.batchRequests(), let collection = requestCollection else {
            return
        }

        upload(startTime: collection.startTime, page: collection.page, requests: requests)
    }

    private func upload(startTime: Millisecond, page: Page, requests: [CapturedRequest]) {
        Task.detached(priority: uploadTaskPriority) {
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
extension CapturedGroupRequestCollector {
    struct Configuration {
        let timerManagingProvider: (NetworkCaptureConfiguration) -> CaptureTimerManaging

        func makeRequestCollector(
            logger: Logging,
            networkCaptureConfiguration: NetworkCaptureConfiguration,
            requestBuilder: CapturedRequestBuilder,
            uploader: Uploading
        ) -> CapturedGroupRequestCollector {
            let timerManager = timerManagingProvider(networkCaptureConfiguration)
            return CapturedGroupRequestCollector(logger: logger,
                                                 timerManager: timerManager,
                                                 requestBuilder: requestBuilder,
                                                 uploader: uploader)
        }

        static var live: Self {
            return Configuration { configuration in
                CaptureTimerManager(configuration: configuration)
            }
        }
    }
}
