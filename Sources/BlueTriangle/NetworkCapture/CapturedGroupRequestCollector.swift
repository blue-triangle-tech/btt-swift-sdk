//
//  CapturedGroupRequestCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/06/25.
//


import Foundation

actor CapturedGroupRequestCollector: CapturedGroupRequestCollecting {
    private let logger: Logging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private let uploadTaskPriority: TaskPriority
    private var requestCollection: GroupRequestCollection?

    init(
        logger: Logging,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading,
        uploadTaskPriority: TaskPriority = .utility
    ) {
        self.logger = logger
        self.requestBuilder = requestBuilder
        self.uploader = uploader
        self.uploadTaskPriority = uploadTaskPriority
    }

    func start(page: Page, startTime: TimeInterval) {
        requestCollection = GroupRequestCollection(page: page, startTime: startTime.milliseconds)
    }

    func collect(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, response: CustomPageResponse){
        requestCollection?.insert(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, response: response)
    }
    
    func uploadCollectedRequests() {
        Task {
            guard let collection = requestCollection, collection.requests.count > 0 else { return }
            upload(startTime: collection.startTime, page: collection.page, requests: collection.requests)
        }
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
            return CapturedGroupRequestCollector(logger: logger,
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
