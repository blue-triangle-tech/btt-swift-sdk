//
//  PerformanceReport.swift
//
//  Created by Mathew Gacy on 1/6/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct PerformanceReport: Codable {
    let minCPU: Float
    let maxCPU: Float
    let avgCPU: Float
    let minMemory: Int
    let maxMemory: Int
    let avgMemory: Int
}
