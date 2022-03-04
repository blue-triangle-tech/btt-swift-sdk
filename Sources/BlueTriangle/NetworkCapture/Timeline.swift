//
//  Timeline.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import DequeModule

struct Timeline<T: Equatable> {
    final class Span {
        let startTime: Millisecond
        var value: T

        init(startTime: Millisecond, value: T) {
            self.startTime = startTime
            self.value = value
        }
    }

    let capacity: Int
    private let intervalProvider: () -> TimeInterval
    private var storage = Deque<Span>()

    var count: Int {
        storage.count
    }

    var current: T? {
        storage.last?.value
    }

    init(capacity: Int = 5, intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        assert(capacity > 0)
        self.capacity = capacity
        self.intervalProvider = intervalProvider
    }

    @discardableResult
    mutating func insert(_ value: T) -> T? {
        storage.append(Span(startTime: intervalProvider().milliseconds, value: value))
        if storage.count > capacity {
            return storage.popFirst()?.value
        }
        return nil
    }

    mutating func updateValue(for startTime: Millisecond, transform: (inout T) -> Void) {
        guard !storage.isEmpty else {
            return
        }
        var currentIndex = storage.count - 1
        repeat {
            if storage[currentIndex].startTime <= startTime {
                transform(&storage[currentIndex].value)
                return
            }
            currentIndex -= 1
        } while currentIndex >= 0
    }

    mutating func updateCurrent(transform: (inout T) -> Void) {
        guard !storage.isEmpty else {
            return
        }
        transform(&storage.last!.value)
    }

    @discardableResult
    mutating func pop() -> T? {
        storage.popFirst()?.value
    }
}

// MARK: - Test Support
extension Timeline {
    func value(for startTime: Millisecond) -> T? {
        guard !storage.isEmpty else {
            return nil
        }
        var currentIndex = storage.count - 1
        repeat {
            if storage[currentIndex].startTime <= startTime {
                return storage[currentIndex].value
            }
            currentIndex -= 1
        } while currentIndex >= 0
        return nil
    }
}
