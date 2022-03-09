//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CapturedRequestCollector: CapturedRequestCollecting {
    private var storage = Timeline<RequestSpan>()
    private let queue: DispatchQueue
    private let logger: Logging
    private var timerManager: CaptureTimerManaging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading

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
            self?.batchCapturedRequests()
        }
    }

    func start(page: Page) {
        queue.async(flags: .barrier) {
            self.timerManager.start()
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

    func collect(timer: InternalTimer, data: Data?, response: URLResponse?) {
        let capturedRequest = CapturedRequest(timer: timer, response: response)
        queue.async(flags: .barrier) {
            self.storage.updateValue(for: timer.startTime.milliseconds) { span in
                span.insert(capturedRequest)
            }
        }
    }

    func batchCapturedRequests() {
        queue.async(flags: .barrier) {
            if let currentSpan = self.storage.batchCurrentRequests() {
                // ?
                self.queue.async {
                    self.upload(currentSpan)
                }
            } else {
                print("Empty span")
            }
        }
    }

    private func upload(_ span: (Millisecond, RequestSpan)) {
        do {
            let request = try requestBuilder.build(span.0, span.1)
            uploader.send(request: request)
        } catch {
            logger.error("Error building request: \(error.localizedDescription)")
        }
    }
}
