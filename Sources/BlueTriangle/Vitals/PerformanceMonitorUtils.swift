//
//  PerformanceMonitorUtils.swift
//
//  Created by Mathew Gacy on 1/21/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

typealias Stats<T: Numeric> = (min: T, max: T, cumulative: T)

func update(stats: inout Stats<Double>, with element: Double) -> Stats<Double> {
    if element < stats.min {
        stats.min = element
    } else if element > stats.max {
        stats.max = element
    }
    stats.cumulative += element
    return stats
}

func update(stats: inout Stats<UInt64>, with element: UInt64) -> Stats<UInt64> {
    if element < stats.min {
        stats.min = element
    } else if element > stats.max {
        stats.max = element
    }
    stats.cumulative += element
    return stats
}
