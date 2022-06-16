//
//  Constants.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

enum Constants {
    static let browser = "Native App"
    static let device = "Mobile"
    static let os = "iOS"
    static let globalUserIDKey = "com.bluetriangle.kGlobalUserIDUserDefault"

    // Settings
    static let minimumSampleInterval: TimeInterval = 1 / 60
    static let sessionTimeoutInMinutes = 30
    static let userSessionTimeoutInDays = 365

    // Endpoints
    static let capturedRequestEndpoint: URL = "https://d.btttag.com/wcdv02.rcv"
    static let errorEndpoint: URL = "https://d.btttag.com/err.rcv"
    static let timerEndpoint: URL = "https://d.btttag.com/analytics.rcv"

    // Crash Tracking
    static let crashID = "iOS Crash"
    static let eTp = "NativeAppCrash"
    static let crashReportFilename = "com.bluetriangle.crash"
    static let crashReportLineSeparator = "~~"

    // Logging
    static let loggingSubsystem = "com.bluetriangle.sdk"
    static let loggingCategory = "tracker"
}
