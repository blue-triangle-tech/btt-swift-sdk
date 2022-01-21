//
//  PerformanceMonitorBuilder.swift
//
//  Created by Mathew Gacy on 1/21/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct PerformanceMonitorBuilder {
    let builder: (TimeInterval) -> () -> PerformanceMonitoring
}

