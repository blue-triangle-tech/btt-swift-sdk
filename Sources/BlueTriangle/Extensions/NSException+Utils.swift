//
//  NSException+Utils.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension NSException {
    var bttCrashReportMessage: String {
        debugDescription.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .joined(separator: Constants.crashReportLineSeparator)
    }
}
