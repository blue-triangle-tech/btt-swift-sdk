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
    private let logger: Logging
    private let timeIntervalProvider: () -> TimeInterval
    private let performanceMonitor: PerformanceMonitoring?

    @objc public var page: Page
    @objc public private(set) var state: State = .initial
    @objc public private(set) var startTime: TimeInterval = 0.0
    @objc public private(set) var interactiveTime: TimeInterval = 0.0
    @objc public private(set) var endTime: TimeInterval = 0.0

    var pageTimeInterval: PageTimeInterval {
        PageTimeInterval(
            startTime: startTime.milliseconds,
            interactiveTime: interactiveTime.milliseconds,
            pageTime: endTime.milliseconds - startTime.milliseconds)
    }

    var performanceReport: PerformanceReport? {
        performanceMonitor?.makeReport()
    }

    init(page: Page,
         logger: Logging,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
         performanceMonitor: PerformanceMonitoring? = nil) {
        self.page = page
        self.logger = logger
        self.timeIntervalProvider = intervalProvider
        self.performanceMonitor = performanceMonitor
    }

    @objc
    public func start() {
        handle(.start)
    }

    @objc
    public func markInteractive() {
        handle(.markInteractive)
    }

    @objc
    public func end() {
        handle(.end)
    }

    private func handle(_ action: Action) {
        lock.sync {
            switch (state, action) {
            case (.initial, .start):
                startTime = timeIntervalProvider()
                performanceMonitor?.start()
                state = .started
            case (.started, .markInteractive):
                interactiveTime = timeIntervalProvider()
                state = .interactive
            case (.started, .end), (.interactive, .end):
                endTime = timeIntervalProvider()
                performanceMonitor?.end()
                state = .ended
            case (.initial, .markInteractive):
                logger.error("Interactive time cannot be set until timer is started.")
            case (.initial, .end):
                logger.error("Cannot end timer before it is started.")
            case (.started, .start):
                logger.error("Start time already set.")
            case (.interactive, .markInteractive):
                logger.error("Interactive time already set.")
            case (.ended, .start), (.ended, .markInteractive), (.ended, .end):
                logger.error("Timer already ended.")
            default:
                logger.error("Invalid transition.")
            }
        }
    }
}

// MARK: - Supporting Types
extension BTTimer {
    struct Configuration {
        let timeIntervalProvider: () -> TimeInterval

        func makeTimerFactory(
            logger: Logging,
            performanceMonitorFactory: (() -> PerformanceMonitoring)? = nil
        ) -> (Page) -> BTTimer {
            { page in
                BTTimer(page: page,
                        logger: logger,
                        intervalProvider: timeIntervalProvider,
                        performanceMonitor: performanceMonitorFactory?() ?? nil)
            }
        }

        static var live = Self(
            timeIntervalProvider: { Date().timeIntervalSince1970 }
        )
    }
}
