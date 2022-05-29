//
//  InternalTimer.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

@usableFromInline
struct InternalTimer {

    enum State {
        case initial
        case started
        case ended
    }

    private enum Action {
        case start
        case end
    }

    private let timeIntervalProvider: () -> TimeInterval
    private let logger: Logging

    private(set) var state: State = .initial
    private(set) var startTime: TimeInterval = 0.0
    private(set) var endTime: TimeInterval = 0.0

    init(logger: Logging,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.logger = logger
        self.timeIntervalProvider = intervalProvider
    }

    mutating func start() {
        handle(.start)
    }

    @usableFromInline
    mutating func end() {
        handle(.end)
    }

    private mutating func handle(_ action: Action) {
        switch (state, action) {
        case (.initial, .start):
            startTime = timeIntervalProvider()
            state = .started
        case (.started, .end):
            endTime = timeIntervalProvider()
            state = .ended
        case (.initial, .end):
            logger.error("Cannot end timer before it is started.")
        case (.started, .start):
            logger.error("Start time already set.")
        case (.ended, .start), (.ended, .end):
            logger.error("Timer already ended.")
        }
    }
}

// MARK: - CustomStringConvertible
extension InternalTimer.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .initial: return ".initial"
        case .started: return ".started"
        case .ended: return ".ended"
        }
    }
}

extension InternalTimer: CustomStringConvertible {
    @usableFromInline
    var description: String {
        "InternalTimer(state: \(state), startTime: \(startTime), endTime: \(endTime))"
    }
}

// MARK: - Supporting Types
extension InternalTimer {
    struct Configuration {
        let timeIntervalProvider: () -> TimeInterval

        func makeTimerFactory(logger: Logging) -> () -> InternalTimer {
            { InternalTimer(logger: logger, intervalProvider: timeIntervalProvider) }
        }

        static let live = Self(
            timeIntervalProvider: { Date().timeIntervalSince1970 }
        )
    }
}
