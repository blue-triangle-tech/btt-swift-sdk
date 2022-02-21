//
//  BlueTriangle.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final public class BlueTriangleConfiguration: NSObject {
    private var customCampaign: String?
    private var customGlobalUserID: Identifier?
    private var customSessionID: Identifier?

    /// Blue Triangle Technologies-assigned site ID.
    @objc public var siteID: String = ""

    /// Session ID.
    @objc public var sessionID: Identifier {
        get {
            Identifier.random()
        }
        set {
            customSessionID = newValue
        }
    }

    /// Global User ID.
    @objc public var globalUserID: Identifier {
        get {
            var id = Identifier(UserDefaults.standard.integer(forKey: Constants.globalUserIDKey))
            if id == 0 {
                id = Identifier.random()
                UserDefaults.standard.set(id, forKey: Constants.globalUserIDKey)
            }
            return id
        }
        set {
            customGlobalUserID = newValue
        }
    }

    /// A/B testing identifier.
    @objc public var abTestID: String = "Default"

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public var campaign: String? = "" {
        didSet { customCampaign = campaign }
    }

    /// Campaign medium.
    @objc public var campaignMedium: String = ""

    /// Campaign name.
    @objc public var campaignName: String = ""

    /// Campaign source.
    @objc public var campaignSource: String = ""

    /// Data center.
    @objc public var dataCenter: String = "Default"

    /// Traffic segment.
    @objc public var trafficSegmentName: String = ""

    /// Crash tracking behavior.
    @objc public var crashTracking: CrashTracking = .none

    /// Controls the frequency at which app performance is sampled. `Constants.minimumSampleInterval` defines the
    /// smallest allowed interval (one measurement every 1/60 of a second).
    @objc public var performanceMonitorSampleRate: TimeInterval = 1

    var makeLogger: () -> Logging = {
        BTLogger.live
    }

    var timerConfiguration: BTTimer.Configuration = .live

    var uploaderConfiguration: Uploader.Configuration = .live

    var requestBuilder: RequestBuilder = .live

    var performanceMonitorBuilder: PerformanceMonitorBuilder = .live
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
                globalUserID: customGlobalUserID ?? globalUserID,
                sessionID: customSessionID ?? sessionID,
                abTestID: abTestID,
                campaign: customCampaign,
                campaignMedium: campaignMedium,
                campaignName: campaignName,
                campaignSource: campaignSource,
                dataCenter: dataCenter,
                trafficSegmentName: trafficSegmentName
        )
    }

    func makePerformanceMonitorFactory() -> (() -> PerformanceMonitoring)? {
        performanceMonitorBuilder.builder(performanceMonitorSampleRate)
    }
}

final public class BlueTriangle: NSObject {

    private static let lock = NSLock()
    private static var configuration = BlueTriangleConfiguration()

    private static var session: Session = {
        configuration.makeSession()
    }()

    private static var logger: Logging = {
        configuration.makeLogger()
    }()

    private static var uploader: Uploading = {
        configuration.uploaderConfiguration.makeUploader(logger: logger)
    }()

    private static var timerFactory: (Page) -> BTTimer = {
        configuration.timerConfiguration.makeTimerFactory(
            logger: logger,
            performanceMonitorFactory: configuration.makePerformanceMonitorFactory())
    }()

    /// A Boolean value indicating whether the SDK has been initialized.
    public private(set) static var initialized = false

    private static var crashReportManager: CrashReportManaging?

    private static var appEventObserver: AppEventObserver?

    /// Blue Triangle Technologies-assigned site ID.
    @objc public static var siteID: String {
        get {
            lock.sync { session.siteID }
        }
    }

    /// Global User ID.
    @objc public static var globalUserID: Identifier {
        get {
            lock.sync { session.globalUserID }
        }
    }

    /// Session ID.
    @objc public static var sessionID: Identifier {
        get {
            lock.sync { session.sessionID }
        }
        set {
            lock.sync { session.sessionID = newValue }
        }
    }

    /// A/B testing identifier.
    @objc public static var abTestID: String  {
        get {
            lock.sync { session.abTestID }
        }
        set {
            lock.sync { session.abTestID = newValue }
        }
    }

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public static var campaign: String?  {
        get {
            lock.sync { session.campaign }
        }
        set {
            lock.sync { session.campaign = newValue}
        }
    }

    /// Campaign medium.
    @objc public static var campaignMedium: String  {
        get {
            lock.sync { session.campaignMedium }
        }
        set {
            lock.sync { session.campaignMedium = newValue }
        }
    }

    /// Campaign name.
    @objc public static var campaignName: String  {
        get {
            lock.sync { session.campaignName }
        }
        set {
            lock.sync { session.campaignName = newValue }
        }
    }

    /// Campaign source.
    @objc public static var campaignSource: String  {
        get {
            lock.sync { session.campaignSource }
        }
        set {
            lock.sync { session.campaignSource = newValue }
        }
    }

    /// Data center.
    @objc public static var dataCenter: String  {
        get {
            lock.sync { session.dataCenter }
        }
        set {
            lock.sync { session.dataCenter = newValue }
        }
    }

    /// Traffic segment.
    @objc public static var trafficSegmentName: String  {
        get {
            lock.sync { session.trafficSegmentName }
        }
        set {
            lock.sync { session.trafficSegmentName = newValue }
        }
    }

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
        let timer = timerFactory(page)
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
    public static func endTimer(_ timer: BTTimer, purchaseConfirmation: PurchaseConfirmation? = nil) {
        timer.end()
        purchaseConfirmation?.orderTime = timer.endTime
        let request: Request
        lock.lock()
        do {
            request = try configuration.requestBuilder.builder(session, timer, purchaseConfirmation)
            lock.unlock()
        } catch  {
            lock.unlock()
            logger.error(error.localizedDescription)
            return
        }
        uploader.send(request: request)
    }
}

extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
        crashReportManager = CrashReportManager(crashConfiguration,
                                                logger: logger,
                                                uploader: uploader)

        appEventObserver = AppEventObserver(onLaunch: {
            crashReportManager?.uploadReports(session: session)
        })
        appEventObserver?.configureNotifications()
    }
}

// MARK: - Test Support
extension BlueTriangle {
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
        let _ = makeTimer(page: .init(pageName: "TEST"))
    }

    static func reconfigure(
        configuration: BlueTriangleConfiguration = .init(),
        session: Session? = nil,
        logger: Logging? = nil,
        uploader: Uploading? = nil,
        timerFactory: ((Page) -> BTTimer)? = nil
    ) {
        lock.sync {
            self.configuration = configuration
            initialized = true
            if let session = session {
                self.session = session
            }
            if let logger = logger {
                self.logger = logger
            }
            if let uploader = uploader {
                self.uploader = uploader
            }
            if let timerFactory = timerFactory {
                self.timerFactory = timerFactory
            }
        }
    }
}
