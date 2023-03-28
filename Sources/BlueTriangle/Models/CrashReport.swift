//
//  CrashReport.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct CrashReport: Codable {
    let sessionID: Identifier
    let report: ErrorReport
}

extension CrashReport {
    init(
        sessionID: Identifier,
        exception: NSException,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.sessionID = sessionID
        self.report = ErrorReport(message: exception.bttCrashReportMessage,
                                  eCnt: 1,
                                  eTp: Constants.eTp,
                                  ver: Version.number,
                                  appName: Bundle.main.appName ?? "Unknown",
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider().milliseconds)
    }
}
