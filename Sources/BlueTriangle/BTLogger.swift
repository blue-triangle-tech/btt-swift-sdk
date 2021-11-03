//
//  BTLogger.swift
//
//  Created by Mathew Gacy on 11/2/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import os.log

protocol Logging {
    func logInfo(
        _ message: () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )

    func logError(
        _ message: () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}

extension Logging {
    func info(
        _ message: @autoclosure () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logInfo(message, file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure () -> String,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        logError(message, file: file, function: function, line: line)
    }
}

struct BTLogger: Logging {
    func logInfo(
        _ message: @autoclosure () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
    }

    func logError(
        _ message: @autoclosure () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
    }
}
