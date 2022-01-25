//
//  PerformanceMonitorBuilder.swift
//
//  Created by Mathew Gacy on 1/21/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct PerformanceMonitorBuilder {
    let builder: (TimeInterval) -> () -> PerformanceMonitoring

    static var live: Self = PerformanceMonitorBuilder { sampleInterval in
        #if os(iOS) || os(tvOS)
        return {
            return DisplayLinkPerformanceMonitor(minimumSampleInterval: .init(sampleInterval),
                                                 resourceUsage: ResourceUsage.self)
        }
        #else
        return {
            TimerPerformanceMonitor(sampleInterval: sampleInterval, resourceUsage: ResourceUsage.self)
        }
        #endif
    }
}
