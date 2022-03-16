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

    let offset: TimeInterval
    private(set) var state: State = .initial
    private(set) var startTime: TimeInterval = 0.0
    private(set) var endTime: TimeInterval = 0.0

    var relativeStartTime: TimeInterval {
        startTime - offset
    }

    var relativeEndTime: TimeInterval {
        endTime - offset
    }

    init(logger: Logging,
         offset: TimeInterval = 0.0,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.logger = logger
        self.offset = offset
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
