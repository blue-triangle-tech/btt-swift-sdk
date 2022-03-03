//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CapturedRequestCollector: CapturedRequestCollecting {
    private let queue: DispatchQueue
    private let logger: Logging
    private var timerManager: CaptureTimerManaging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private var requests: [CapturedRequest] = []

    init(
        queue: DispatchQueue,
        logger: Logging,
        timerManager: CaptureTimerManaging,
        requestBuilder: CapturedRequestBuilder,
        uploader: Uploading
    ) {
        self.queue = queue
        self.logger = logger
        self.timerManager = timerManager
        self.requestBuilder = requestBuilder
        self.uploader = uploader
        self.timerManager.handler = { [weak self] in
            self?.timerFired()
        }
    }

    func start(page: Page) {
        timerManager.start()
        // ...
    }

    func collect(timer: InternalTimer, data: Data?, response: URLResponse?) {
        // ...
    }

    func timerFired() {
        // ...
    }

    func uploadCapturedRequests(session: Session, page: Page, pageTimeInterval: PageTimeInterval)throws {
        let request = try requestBuilder.build(session, page, pageTimeInterval, requests)
        uploader.send(request: request)
    }
}
