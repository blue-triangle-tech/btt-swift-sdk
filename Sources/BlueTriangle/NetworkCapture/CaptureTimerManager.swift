//
//  CaptureTimerManager.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

final class CaptureTimerManager: CaptureTimerManaging {
    enum State: Equatable {
        case inactive
        case active(span: Int)
    }

    private enum Action {
        case start
        case pause
        case fire
    }

    private let timerFlags: DispatchSource.TimerFlags = []
    private let timerLeeway: DispatchTimeInterval
    private let queue: DispatchQueue
    private let configuration: NetworkCaptureConfiguration
    private var timer: DispatchSourceTimer?
    private(set) var state: State = .inactive
    var handler: () -> Void

    init(
        queue: DispatchQueue,
        configuration: NetworkCaptureConfiguration,
        timerLeeway: DispatchTimeInterval = .seconds(1),
        handler: @escaping () -> Void = { }
    ) {
        self.queue = queue
        self.configuration = configuration
        self.timerLeeway = timerLeeway
        self.handler = handler
    }

    deinit {
        if case .active = state {
            timer?.cancel()
        }
    }

    func start() {
        handle(.start)
    }

    func cancel() {
        handle(.pause)
    }
}

private extension CaptureTimerManager {
    func makeTimer(delay: TimeInterval) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(flags: timerFlags, queue: queue)
        timer.schedule(deadline: .now() + delay, leeway: timerLeeway)
        timer.setEventHandler { [weak self] in
            self?.handle(.fire)
        }
        return timer
    }

    func handle(_ action: Action) {
        switch (state, action) {
        case (.inactive, .start):
            timer = makeTimer(delay: configuration.initialSpanDuration)
            timer?.activate()
            state = .active(span: 1)
        case (.active, .start):
            timer?.cancel()
            timer = makeTimer(delay: configuration.initialSpanDuration)
            timer?.activate()
            state = .active(span: 1)
        case (.active(let span), .fire):
            handler()
            let nextSpan = span + 1
            if nextSpan <= configuration.spanCount {
                timer = makeTimer(delay: configuration.subsequentSpanDuration)
                timer?.activate()
                state = .active(span: nextSpan)
            } else {
                // Timer should not be active, but cancel to be safe.
                timer?.cancel()
                timer = nil
                state = .inactive
            }
        case (.inactive, .fire):
            #if DEBUG
            print("\(#function) - Unanticipated timer fire.")
            #endif
            timer?.cancel()
            timer = nil
        case (.inactive, .pause):
            return
        case (.active, .pause):
            timer?.cancel()
            timer = nil
            state = .inactive
        }
    }
}
