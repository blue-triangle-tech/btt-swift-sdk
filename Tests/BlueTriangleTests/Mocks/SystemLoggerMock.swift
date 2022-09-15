//
//  SystemLoggerMock.swift
//
//  Created by Mathew Gacy on 9/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest
import os.log
@testable import BlueTriangle

final class SystemLoggerMock: SystemLogging {
    var onLog: (OSLogType, String) -> Void

    init(onLog: @escaping (OSLogType, String) -> Void = { _, _ in }) {
        self.onLog = onLog
    }

    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        onLog(level, message())
    }
}
