//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CapturedRequestCollector: CapturedRequestCollecting {
    private let logger: Logging
    private let requestBuilder: CapturedRequestBuilder
    private let uploader: Uploading
    private var requests: [CapturedRequest] = []

    init(logger: Logging, requestBuilder: CapturedRequestBuilder, uploader: Uploading) {
        self.logger = logger
        self.requestBuilder = requestBuilder
        self.uploader = uploader
    }

    func collect(timer: InternalTimer, data: Data?, response: URLResponse?) {
        // ...
    }

    func uploadCapturedRequests(session: Session, page: Page, pageTimeInterval: PageTimeInterval)throws {
        let request = try requestBuilder.build(session, page, pageTimeInterval, requests)
        uploader.send(request: request)
    }
}
