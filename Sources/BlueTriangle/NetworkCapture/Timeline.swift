//
//  Timeline.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct Timeline<T> {
    final class Span {
        let startTime: Millisecond
        var value: T

        var next: Span?
        weak var previous: Span?

        init(startTime: Millisecond, value: T, previous: Span? = nil) {
            self.startTime = startTime
            self.value = value
            self.previous = previous
        }
    }

    private let intervalProvider: () -> TimeInterval
    let capacity: Int
    private(set) var count: Int = 0
    private var head: Span?
    private var tail: Span?

    var current: T? {
        tail?.value
    }

    var isEmpty: Bool {
        head == nil
    }

    init(capacity: Int = 5, intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        assert(capacity > 0)
        self.capacity = capacity
        self.intervalProvider = intervalProvider
    }

    @discardableResult
    mutating func insert(_ value: T) -> T? {
        insert(value: value)
        return count > capacity ? pop() : nil
    }

    func updateValue(for startTime: Millisecond, transform: (inout T) -> Void) {
        guard let span = span(for: startTime) else {
            return
        }
        transform(&span.value)
    }

    func updateCurrent(transform: (inout T) -> Void) {
        guard let tail = tail else {
            return
        }
        transform(&tail.value)
    }

    func value(for startTime: Millisecond) -> T? {
        span(for: startTime)?.value
    }

    @discardableResult
    mutating func pop() -> T? {
        guard !isEmpty else {
            return nil
        }

        defer {
            head = head?.next
            if isEmpty {
                tail = nil
            }
        }
        count -= 1
        return head?.value
    }
}

private extension Timeline {
    private func span(for startTime: Millisecond) -> Span? {
        var span = tail
        while span != nil {
            if span!.startTime <= startTime {
                return span
            }
            span = span?.previous
        }
        return nil
    }

    private mutating func insert(value: T) {
        let new = Span(startTime: intervalProvider().milliseconds, value: value, previous: tail)
        if isEmpty {
            head = new
        }

        tail?.next = new
        tail = new

        count += 1
    }
}

extension Timeline where T == RequestSpan {
    func resetTail() -> RequestSpan? {
        defer {
            tail?.value.requests = []
        }
        return tail?.value
    }
}
