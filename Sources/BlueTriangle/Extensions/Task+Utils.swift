//
//  Task+Utils.swift
//
//  Created by Mathew Gacy on 1/13/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

// https://www.swiftbysundell.com/articles/delaying-an-async-swift-task/
extension Task where Failure == Error {
    @discardableResult
    static func delayed(
        byTimeInterval delayInterval: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            let delay = UInt64(delayInterval * 1_000_000_000)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            return try await operation()
        }
    }
}
