//
//  Constants.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

enum Constants {
    static let browserName = "Native App"
    static let globalUserIDKey = "com.bluetriangle.kGlobalUserIDUserDefault"
    static let timerEndpoint: URL = "https://d.btttag.com/analytics.rcv"
    static let errorEndpoint: URL = "https://d.btttag.com/err.rcv"

    static let sessionTimeoutInMinutes = 30
    static let userSessionTimeoutInDays = 365

    // Crash Tracking
    static let crashID = "iOS%20Crash"
    static let eTp = "NativeAppCrash"
    static let crashReportFilename = "com.bluetriangle.crash"
    static let crashReportLineSeparator = "~~"

    // Logging
    static let loggingSubsystem = "com.bluetriangle.sdk"
    static let loggingCategory = "tracker"
}
