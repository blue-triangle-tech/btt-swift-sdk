//
//  Untitled.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//
import Foundation

struct ActionRequestCollector: Equatable {
    let page: Page
    var startTime: Millisecond
    var requests: [CapturedRequest]

    var isNotEmpty: Bool {
        !requests.isEmpty
    }

    init(page: Page, startTime: Millisecond, requests: [CapturedRequest] = []) {
        self.page = page
        self.startTime = startTime
        self.requests = requests
    }
    
    mutating func updateNetworkCapture(pageName : String, startTime: Millisecond) {
        self.page.pageName = pageName
        self.startTime = startTime
    }
    
    mutating func insert(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, action: UserAction) async {
        await requests.append(CapturedRequest(startTime: startTime, endTime: endTime, groupStartTime: groupStartTime, action: action))
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
extension ActionRequestCollector: CustomStringConvertible {
    var description: String {
        "RequestCollection(pageName: \(page.pageName), requestCount: \(requests.count)"
    }
}

