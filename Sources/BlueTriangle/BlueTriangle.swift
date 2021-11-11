//
//  BlueTriangle.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final public class BlueTriangleConfiguration: NSObject {
    private var customCampaign: String?

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
    @objc public var campaign: String? = "" { // `campaign`
        didSet { customCampaign = campaign }
    }

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

    /// Crash Tracking Behavior.
    @objc public var crashTracking: CrashTracking = .none

    var timerConfiguration: BTTimer.Configuration = .live

    var uploaderConfiguration: Uploader.Configuration = .live

    var requestBuilder: RequestBuilder = .live
}

// MARK: - Supporting Types
extension BlueTriangleConfiguration {

    @objc
    public enum CrashTracking: Int {
        case none
        case nsException

        var configuration: CrashReportConfiguration? {
            switch self {
            case .none: return nil
            case .nsException: return .nsException
            }
        }
    }

    func makeSession() -> Session {
        Session(siteID: siteID,
                globalUserID: globalUserID,
                sessionID: sessionID,
                abTestID: abTestID,
                campaign: customCampaign,
                campaignMedium: campaignMedium,
                campaignName: campaignName,
                campaignSource: campaignSource,
                dataCenter: dataCenter,
                trafficSegmentName: trafficSegmentName
        )
    }
}

final public class BlueTriangle: NSObject {

    private static let lock = NSLock()
    private static var configuration = BlueTriangleConfiguration()

    private static var uploader: Uploading = {
        configuration.uploaderConfiguration.makeUploader()
    }()

    public private(set) static var initialized = false

    private static var crashReportManager: CrashReportManaging?

    private static var appEventObserver: AppEventObserver?

    @objc
    public static func configure(_ configure: (BlueTriangleConfiguration) -> Void) {
        lock.sync {
            precondition(!Self.initialized, "BlueTriangle can only be initialized once.")
            initialized.toggle()
            configure(configuration)
            if let crashConfig = configuration.crashTracking.configuration {
                DispatchQueue.global(qos: .utility).async {
                    configureCrashTracking(with: crashConfig)
                }
            }
        }
    }

    @objc
    public static func makeTimer(page: Page) -> BTTimer {
        lock.lock()
        precondition(initialized, "BlueTriangle must be initialized before sending timers.")
        let timer = configuration.timerConfiguration.timerFactory()(page)
        lock.unlock()
        return timer
    }

    @objc
    public static func startTimer(page: Page) -> BTTimer {
        let timer = makeTimer(page: page)
        timer.start()
        return timer
    }

    @objc
    public static func endTimer(_ timer: BTTimer) {
        timer.end()
        let request: Request
        lock.lock()
        do {
            request = try configuration.requestBuilder.builder(configuration.makeSession(), timer)
            lock.unlock()
        } catch  {
            lock.unlock()
            print(error) // FIXME: add actual implementation
            return
        }
        uploader.send(request: request)
    }
}

extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
        crashReportManager = CrashReportManager(crashConfiguration,
                                                log: { print($0) },
                                                uploader: uploader)

        appEventObserver = AppEventObserver(onLaunch: {
            crashReportManager?.uploadReports(session: configuration.makeSession())
        })
        appEventObserver?.configureNotifications()
    }
}

extension BlueTriangle {
    // Support for testing
    @objc
    static func reset() {
        lock.sync {
            configuration = BlueTriangleConfiguration()
            initialized = false
        }
    }

    @objc
    static func prime() {
        let _ = uploader
    }
}
