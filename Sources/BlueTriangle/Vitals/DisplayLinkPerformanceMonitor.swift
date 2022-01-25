//
//  DisplayLinkPerformanceMonitor.swift
//
//  Created by Mathew Gacy on 1/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#endif

@available(iOS 13.0, tvOS 7.0, *)
final class DisplayLinkPerformanceMonitor: PerformanceMonitoring {
    public enum State {
        case initial
        case started
        case paused
        case ended
    }

    enum Action {
        case start
        case pause
        case end
    }

    private let minimumSampleInterval: CFTimeInterval
    private let resourceUsage: ResourceUsageMeasuring.Type
    private var displayLink: CADisplayLink!
    private var lastSampleTimestamp: CFTimeInterval = .zero

    private(set) var measurements: [ResourceUsageMeasurement] = []
    private(set) var state: State = .initial

    init(
        minimumSampleInterval: CFTimeInterval,
        resourceUsage: ResourceUsageMeasuring.Type,
        runLoop: RunLoop = .current,
        mode: RunLoop.Mode = .common
    ) {
        self.minimumSampleInterval = minimumSampleInterval
        self.resourceUsage = resourceUsage
        let displayLink = CADisplayLink(target: self, selector: #selector(step(displayLink:)))
        displayLink.isPaused = true
        displayLink.add(to: runLoop, forMode: mode)
        self.displayLink = displayLink
    }

    func start() {
        handle(.start)
    }

    func end() {
        handle(.end)
    }

    func makeReport() -> PerformanceReport {
        measurements.makeReport() ?? .empty
    }

    private func handle(_ action: Action) {
        switch (state, action) {
        case (.initial, .start):
            displayLink.isPaused = false
            state = .started
        case (.started, .pause):
            displayLink.isPaused = true
            state = .paused
        case (.started, .end), (.paused, .end):
            displayLink.invalidate()
            sample()
            state = .ended
        default:
            break
        }
    }

    @objc private func step(displayLink: CADisplayLink) {
        guard displayLink.timestamp - lastSampleTimestamp > minimumSampleInterval else {
            return
        }
        guard 1 / (displayLink.targetTimestamp - displayLink.timestamp) > 60 else {
            handle(.pause)
            return
        }
        sample()
    }

    private func sample() {
        lastSampleTimestamp = displayLink.timestamp
        measurements.append(resourceUsage.measure())
    }
}

