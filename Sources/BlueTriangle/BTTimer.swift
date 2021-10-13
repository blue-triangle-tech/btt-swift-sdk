//
//  BTTimer.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final public class BTTimer: NSObject {

    @objc
    public enum State: Int {
        case initial
        case started
        case interactive
        case ended
    }

    enum Action {
        case start
        case markInteractive
        case end
    }

    private let lock = NSLock()
    private let timeIntervalProvider: () -> TimeInterval
    private let log: (String) -> Void = { _ in }

    @objc public let page: Page
    @objc public private(set) var state: State = .initial
    @objc public private(set) var startTime: TimeInterval = 0.0
    @objc public private(set) var interactiveTime: TimeInterval = 0.0
    @objc public private(set) var endTime: TimeInterval = 0.0

    init(page: Page,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }) {
        self.page = page
        self.timeIntervalProvider = intervalProvider
    }

    @objc public func markInteractive() {
        handle(.markInteractive)
    }

    func start() {
        handle(.start)
    }

    @objc public func end() {
        handle(.end)
    }

    private func handle(_ action: Action) {
        lock.sync {
            switch (state, action) {
            case (.initial, .start):
                startTime = timeIntervalProvider()
                state = .started
            case (.started, .markInteractive):
                interactiveTime = timeIntervalProvider()
                state = .interactive
            case (.started, .end), (.interactive, .end):
                endTime = timeIntervalProvider()
                state = .ended
            case (.initial, .markInteractive):
                log("Interactive time cannot be set until timer is started.")
            case (.initial, .end):
                log("Cannot end timer before it is started.")
            case (.started, .start):
                log("Start time already set.")
            case (.interactive, .markInteractive):
                log("Interactive time already set.")
            case (.ended, .start), (.ended, .markInteractive), (.ended, .end):
                log("Timer already ended.")
            default:
                log("Invalid transition.")
            }
        }
    }
}
