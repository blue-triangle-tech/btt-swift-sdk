//
//  BTTimer.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object that measures the duration of a user interaction.
final public class BTTimer: NSObject {
    /// Describes the timer type.
    @objc
    public enum TimerType: Int {
        /// A timer used to measure primary user interactions and captured network requests.
        case main
        /// A timer used to measure user interactions of secondary importance.
        case secondary
    }

    /// Describes the state of a timer.
    @objc
    public enum State: Int {
        /// Timer has not yet been started.
        case initial
        /// Timer has been started.
        case started
        /// Timer has been marked interactive.
        case interactive
        /// Timer has been ended.
        case ended
    }

    private enum Action {
        case start
        case markInteractive
        case end
    }

    private let lock = NSLock()
    private let logger: Logging
    private let timeIntervalProvider: () -> TimeInterval
    private let performanceMonitor: PerformanceMonitoring?

    /// The type of the timer.
    @objc public let type: TimerType

    /// An object describing the user interaction measured by the timer.
    @objc public var page: Page

    /// The state of the timer.
    @objc public private(set) var state: State = .initial

    /// The epoch time interval at which the timer was started.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var startTime: TimeInterval = 0.0

    /// The epoch time interval at which the timer was marked interactive.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var interactiveTime: TimeInterval = 0.0

    /// The epoch time interval at which the timer was ended.
    ///
    /// The default value is `0.0`.
    @objc public private(set) var endTime: TimeInterval = 0.0
    @objc public var hasEnded: Bool {
        switch state {
        case .ended: return true
        default: return false
        }
    }

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
         type: TimerType = .main,
         logger: Logging,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 },
         performanceMonitor: PerformanceMonitoring? = nil) {
        self.page = page
        self.type = type
        self.logger = logger
        self.timeIntervalProvider = intervalProvider
        self.performanceMonitor = performanceMonitor
    }

    /// Start the timer if not already started.
    ///
    /// If already started, will log an error.
    @objc
    public func start() {
        handle(.start)
    }

    /// Mark the timer interactive at current time if the timer has been started and not
    /// already marked interactive.
    ///
    /// If the timer has not been started yet or has already been marked interactive,
    /// calling this method will log an error.
    @objc
    public func markInteractive() {
        handle(.markInteractive)
    }

    /// End the timer.
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
                return
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
        ) -> (Page, BTTimer.TimerType) -> BTTimer {
            { page, timerType in
                BTTimer(page: page,
                        logger: logger,
                        intervalProvider: timeIntervalProvider,
                        performanceMonitor: performanceMonitorFactory?())
            }
        }

        static let live = Self(
            timeIntervalProvider: { Date().timeIntervalSince1970 }
        )
    }
}
