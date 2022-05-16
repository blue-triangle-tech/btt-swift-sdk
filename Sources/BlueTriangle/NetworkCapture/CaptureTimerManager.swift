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
        case active(task: Task<Void, Error>, span: Int)
    }

    private enum Action {
        case start
        case pause
        case fire
    }

    private let configuration: NetworkCaptureConfiguration
    private let taskPriority: TaskPriority
    private(set) var state: State = .inactive
    var handler: (() -> Void)?

    init(
        configuration: NetworkCaptureConfiguration,
        taskPriority: TaskPriority = .low
    ) {
        self.configuration = configuration
        self.taskPriority = taskPriority
    }

    deinit {
        if case let .active(task, _) = state {
            task.cancel()
        }
    }

    func start() {
        handle(.start)
    }

    func cancel() {
        handle(.pause)
    }
}

 extension CaptureTimerManager {
    private func makeTask(delay: TimeInterval) -> Task<Void, Error> {
        Task(priority: taskPriority) {
            try await Task.sleep(nanoseconds: delay.nanoseconds)
            handle(.fire)
        }
    }

    private func handle(_ action: Action) {
        switch (state, action) {
        case (.inactive, .start):
            let task = makeTask(delay: configuration.initialSpanDuration)
            state = .active(task: task, span: 1)
        case let (.active(task, _), .start):
            task.cancel()
            let newTask = makeTask(delay: configuration.initialSpanDuration)
            state = .active(task: newTask, span: 1)
            return
        case let (.active(_, span), .fire):
            handler?()
            let nextSpan = span + 1
            if nextSpan <= configuration.spanCount {
                let newTask = makeTask(delay: configuration.subsequentSpanDuration)
                state = .active(task: newTask, span: nextSpan)
            } else {
                state = .inactive
            }
        case (.inactive, .fire):
            return
        case (.inactive, .pause):
            return
        case let (.active(timer, _), .pause):
            timer.cancel()
            state = .inactive
        }
    }
}
