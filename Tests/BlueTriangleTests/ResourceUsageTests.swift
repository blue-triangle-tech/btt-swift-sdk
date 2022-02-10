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

    /// Simulator: iOS 15.2 - 0.026 sec for 100_000 iterations
    /// average: 0.026
    /// relative standard deviation: 34.318%
    /// values: [0.050348, 0.031357, 0.024016, 0.021410, 0.021321, 0.022200, 0.021217, 0.021311, 0.021248, 0.021324]
    func testPerformanceBaseline() throws {
        var measurements: [ResourceUsageMeasurement] = []

        self.measure {
            for _ in 0 ..< measurementCount {
                measurements.append(ResourceUsageMock.measure())
            }
        }
    }

    /// Simulator: iOS 15.2 - 0.895 sec for 100_000 iterations
    /// average: 0.895
    /// relative standard deviation: 22.041%
    /// values: [1.145100, 1.076596, 1.121668, 1.146508, 0.928310, 0.719839, 0.712637, 0.678583, 0.713013, 0.710146]
    func testPerformance() throws {
        var measurements: [ResourceUsageMeasurement] = []

        self.measure {
            for _ in 0 ..< measurementCount {
                measurements.append(ResourceUsage.measure())
            }
        }
    }
}
