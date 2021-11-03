//
//  BTLogger.swift
//
//  Created by Mathew Gacy on 11/2/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import os.log

// MARK: - SystemLogging

// https://stackoverflow.com/a/62488271/4472195
fileprivate extension OSLog {
    func callAsFunction(_ s: String) {
        os_log("%{public}s", log: self, s)
    }
}

protocol SystemLogging {
    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

struct OSLogWrapper: SystemLogging {
    private let logger: OSLog

    init(subsystem: String, category: String) {
        self.logger = OSLog(subsystem: subsystem, category: category)
    }

    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.callAsFunction("\(function):\(line) - \(message())")
    }
}

@available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *)
struct LoggerWrapper: SystemLogging {
    private let logger: Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.log(level: level, "\(function):\(line) - \(message())")
    }
}

// MARK: - Logging

protocol Logging {
    func logInfo(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func logError(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

extension Logging {
    func info(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logInfo(message, file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure @escaping () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logError(message, file: file, function: function, line: line)
    }
}

// MARK: - BTLogger

final class BTLogger: Logging {
    private let logger: SystemLogging

    init() {
        if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, macOS 11.0, *) {
            self.logger = LoggerWrapper(subsystem: Constants.loggingSubsystem, category: Constants.loggingCategory)
        } else {
            self.logger = OSLogWrapper(subsystem: Constants.loggingSubsystem, category: Constants.loggingCategory)
        }
    }

    func logInfo(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.log(level: .info, message: message, file: file, function: function, line: line)
    }

    func logError(
        _ message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        logger.log(level: .error, message: message, file: file, function: function, line: line)
    }
}

extension BTLogger {
    static let live: Logging = {
        BTLogger()
    }()
}
