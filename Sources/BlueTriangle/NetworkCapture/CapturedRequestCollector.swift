//
//  CapturedRequestCollector.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CapturedRequestCollector: CapturedRequestCollecting {
    private let logger: Logging
    private let uploader: Uploading

    init(logger: Logging, uploader: Uploading) {
        self.logger = logger
        self.uploader = uploader
    }

    func collect(timer: InternalTimer, data: Data?, response: URLResponse?) {
        // ...
    }
}
