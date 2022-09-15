//
//  BTLoggerTests.swift
//
//  Created by Mathew Gacy on 9/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
import os.log
@testable import BlueTriangle

final class BTLoggerTests: XCTestCase {

    func testDebugLogEnabled() throws {
        let expectedMessage = "message"

        let systemLogger = SystemLoggerMock { level, message in
            XCTAssertEqual(level, .debug)
            XCTAssertEqual(message, expectedMessage)
        }

        let logger = BTLogger(logger: systemLogger, enableDebug: true)
        logger.debug(expectedMessage)
    }

    func testDebugLogDisabled() throws {
        let systemLogger = SystemLoggerMock { level, message in
            XCTFail("Unexpected debug message")
        }

        let logger = BTLogger(logger: systemLogger, enableDebug: false)
        logger.debug("message")
    }
}
