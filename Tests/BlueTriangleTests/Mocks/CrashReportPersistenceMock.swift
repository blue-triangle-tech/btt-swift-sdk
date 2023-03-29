//
//  CrashReportPersistenceMock.swift
//
//  Created by Mathew Gacy on 3/29/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

struct CrashReportPersistenceMock: CrashReportPersisting {
    static var onRead: () -> CrashReport? = { XCTFail("CrashReportPersistenceMock.read"); return nil }
    static var onClear: () -> Void = { XCTFail("CrashReportPersistenceMock.clear") }

    static func read() -> CrashReport? {
        onRead()
    }

    static func clear() {
        onClear()
    }

    // MARK: Helpers

    static func configure(
        onRead: @escaping () -> CrashReport?,
        onClear: @escaping () -> Void
    ) {
        self.onRead = onRead
        self.onClear = onClear
    }

    static func reset() {
        onRead = { XCTFail("CrashReportPersistenceMock.read"); return nil }
        onClear = { XCTFail("CrashReportPersistenceMock.clear") }
    }
}
