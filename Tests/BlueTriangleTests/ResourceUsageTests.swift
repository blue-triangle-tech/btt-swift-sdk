//
//  ResourceUsageTests.swift
//
//  Created by Mathew Gacy on 1/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

class ResourceUsageTests: XCTestCase {
    let measurementCount = 100_000

    /// Simulator: iOS 15.2 - 0.029 sec for 100_000 iterations
    /// average: 0.029
    /// relative standard deviation: 35.672%
    /// values: [0.055727, 0.034863, 0.034524, 0.023365, 0.022974, 0.023218, 0.022521, 0.022521, 0.023343, 0.022464]
    func testPerformanceBaseline() throws {
        var cpuReadings: [Double] = []
        var memoryReadings: [UInt64] = []

        self.measure {
            for _ in 0 ..< measurementCount {
                let (cpu, memory) = ResourceUsageMock.measure()
                cpuReadings.append(cpu)
                memoryReadings.append(memory)
            }
        }
    }

    /// Simulator: iOS 15.2 - 1.089 sec for 100_000 iterations
    /// average: 1.089
    /// relative standard deviation: 16.960%
    /// values: [1.387169, 1.294715, 1.284556, 1.269837, 0.915502, 0.915120, 0.954772, 0.922236, 0.917705, 1.029545]
    func testPerformance() throws {
        var cpuReadings: [Double] = []
        var memoryReadings: [UInt64] = []

        self.measure {
            for _ in 0 ..< measurementCount {
                let (cpu, memory) = ResourceUsage.measure()
                cpuReadings.append(cpu)
                memoryReadings.append(memory)
            }
        }
    }
}
