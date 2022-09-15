//
//  ResourceUsageMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

struct ResourceUsageMock: ResourceUsageMeasuring {
    static func cpu() -> Double {
        0.25
    }

    static func memory() -> UInt64 {
        100
    }
}
