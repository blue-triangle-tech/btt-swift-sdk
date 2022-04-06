//
//  RequestSpan.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct RequestSpan: Equatable {
    let page: Page
    var requests: [CapturedRequest]

    var isNotEmpty: Bool {
        !requests.isEmpty
    }

    init(_ page: Page, requests: [CapturedRequest] = []) {
        self.page = page
        self.requests = requests
    }

    mutating func insert(_ request: CapturedRequest) {
        requests.append(request)
    }

    mutating func batchRequests() -> [CapturedRequest]? {
        guard isNotEmpty else {
            return nil
        }
        defer { requests = [] }
        return requests
    }
}

// MARK: - CustomStringConvertible
extension RequestSpan: CustomStringConvertible {
    var description: String {
        "RequestSpan(pageName: \(page.pageName), requestCount: \(requests.count)"
    }
}
