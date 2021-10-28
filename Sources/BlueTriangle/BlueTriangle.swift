//
//  BlueTriangle.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final public class BlueTriangleConfiguration: NSObject {

    /// Blue Triangle Technologies-assigned site ID.
    @objc public var siteID: String = ""

    /// Session ID.
    @objc public var sessionID: Identifier = 0 // `sID`

    /// Global User ID
    @objc public var globalUserID: Identifier = 0 // `gID`

    /// A/B testing identifier.
    @objc public var abTestID: String = "Default" // `AB`

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public var campaign: String? = "" // `campaign`

    /// Campaign medium.
    @objc public var campaignMedium: String = "" // `CmpM`

    /// Campaign name.
    @objc public var campaignName: String = "" // `CmpN`

    /// Campaign source.
    @objc public var campaignSource: String = "" // `CmpS`

    /// Data center.
    @objc public var dataCenter: String = "Default" // `DCTR`

    /// Traffic segment.
    @objc public var trafficSegmentName: String = "" // `txnName`

    var timerConfiguration: BTTimer.Configuration = .live
}

final public class BlueTriangle: NSObject {

    private static let lock = NSLock()
    private static var configuration = BlueTriangleConfiguration()

    public private(set) static var initialized = false

    @objc
    public static func configure(_ configure: (BlueTriangleConfiguration) -> Void) {
        lock.sync {
            precondition(!Self.initialized, "BlueTriangle can only be initialized once.")
            configure(configuration)
            Self.initialized = true
        }
    }

    @objc
    public static func makeTimer(page: Page) -> BTTimer {
        let timer = configuration.timerConfiguration.timerFactory()(page)
        return timer
    }

    @objc
    public static func startTimer(page: Page) -> BTTimer {
        let timer = configuration.timerConfiguration.timerFactory()(page)
        timer.start()
        return timer
    }

    @objc
    public static func endTimer(_ timer: BTTimer) {
        timer.end()
        // ...
    }
}
