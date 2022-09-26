//
//  CrashReport.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct CrashReport: Codable {
    let message: String
    let btV: String
    let eTp: String
    let eCnt: Int
    let appName: String
    let line: Int
    let column: Int
    let time: Millisecond

    enum CodingKeys: String, CodingKey {
        case message = "msg"
        case btV
        case eTp
        case eCnt
        case appName = "url"
        case line
        case column = "col"
        case time
    }
}

extension CrashReport {
    init(
        exception: NSException,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.message = exception.bttCrashReportMessage
        self.eCnt = 1
        self.btV = Version.number
        self.eTp = Constants.eTp
        self.appName = Bundle.main.appName ?? "Unknown"
        self.line = 1
        self.column = 1
        self.time = intervalProvider().milliseconds
    }
}
