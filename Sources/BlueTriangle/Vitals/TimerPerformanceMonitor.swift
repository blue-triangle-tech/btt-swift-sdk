//
//  TimerPerformanceMonitor.swift
//
//  Created by Mathew Gacy on 1/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

class TimerPerformanceMonitor: PerformanceMonitoring {
    private let sampleInterval: TimeInterval
    private let resourceUsage: ResourceUsageMeasuring.Type

    private(set) var measurements: [ResourceUsageMeasurement] = []

    init(sampleInterval: TimeInterval, resourceUsage: ResourceUsageMeasuring.Type) {
        self.sampleInterval = sampleInterval
        self.resourceUsage = resourceUsage
    }

    func start() {
        // ...
    }

    func end() {
        // ...
    }

    func makeReport() -> PerformanceReport {
        .init(minCPU: 0.0, maxCPU: 0.0, avgCPU: 0.0, minMemory: 0, maxMemory: 0, avgMemory: 0)
    }

    // MARK: - Private

    private func sample() {
        measurements.append(resourceUsage.measure())
    }
}
