//
//  LoggerMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

class LoggerMock: Logging {
    var onInfo: (String) -> Void
    var onError: (String) -> Void

    init(onInfo: @escaping (String) -> Void = { _ in }, onError: @escaping (String) -> Void = { _ in }) {
        self.onInfo = onInfo
        self.onError = onError
    }

    func logInfo(_ message: @autoclosure () -> String, file: StaticString, function: StaticString, line: UInt) {
        onInfo(message())
    }

    func logError(_ message: @autoclosure () -> String, file: StaticString, function: StaticString, line: UInt) {
        onError(message())
    }

    func reset() {
        onInfo = { _ in }
        onError = { _ in }
    }
}
