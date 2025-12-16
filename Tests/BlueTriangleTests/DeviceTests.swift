//
//  DeviceTests.swift
//
//  Created by Mathew Gacy on 7/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class DeviceTests: XCTestCase {
    @MainActor func testOSInfo() {
        Device.current.loadDeviceInfo()
        let os = Device.current.os
        let osVersion = Device.current.osVersion
        let name = Device.current.name

        #if os(iOS)
        XCTAssertEqual(os, "iOS")
        #elseif os(tvOS)
        XCTAssertEqual(os, "tvOS")
        #elseif os(watchOS)
        XCTAssertEqual(os, "watchOS")
        #elseif os(macOS)
        XCTAssertEqual(os, "macOS")
        #endif

        XCTAssertFalse(osVersion.isEmpty)
        XCTAssertFalse(name.isEmpty)
    }
}
