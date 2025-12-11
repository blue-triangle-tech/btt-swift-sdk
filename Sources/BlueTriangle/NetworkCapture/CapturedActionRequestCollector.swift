//
//  ActionRequestCollection.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//

import Foundation

actor CapturedActionRequestCollector: CapturedActionRequestCollecting {
    private let logger: Logging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private let uploadTaskPriority: TaskPriority
    private var requestCollection: ActionRequestCollection?

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

    func start(page: Page, startTime: Millisecond) {
        requestCollection = ActionRequestCollection(page: page, startTime: startTime)
    }

    func collect(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, action: UserAction) async{
        guard var collection = requestCollection else { return }
        await collection.insert(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, action: action)
        requestCollection = collection
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
extension CapturedActionRequestCollector {
    struct Configuration {
        let timerManagingProvider: (NetworkCaptureConfiguration) -> CaptureTimerManaging

        func makeRequestCollector(
            logger: Logging,
            networkCaptureConfiguration: NetworkCaptureConfiguration,
            requestBuilder: CapturedRequestBuilder,
            uploader: Uploading
        ) -> CapturedActionRequestCollector {
            return CapturedActionRequestCollector(logger: logger,
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
