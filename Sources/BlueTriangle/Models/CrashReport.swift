//
//  CrashReport.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct CrashReport: Codable {

    struct Report: Codable {
        let message: String
        let eCnt: Int
        let eTp: String
        let ver: String
        let appName: String
        let line: Int
        let column: Int
        let time: Millisecond

        enum CodingKeys: String, CodingKey {
            case message = "msg"
            case eCnt
            case eTp
            case ver = "VER"
            case appName = "url"
            case line
            case column = "col"
            case time
        }
    }

    let sessionID: Identifier
    let report: Report

    init(
        sessionID: Identifier,
        exception: NSException,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.sessionID = sessionID
        self.report = Report(message: exception.bttCrashReportMessage,
                           eCnt: 1,
                           eTp: Constants.eTp,
                           ver: Version.number,
                           appName: Bundle.main.appName ?? "Unknown",
                           line: 1,
                           column: 1,
                           time: intervalProvider().milliseconds)
    }
}
