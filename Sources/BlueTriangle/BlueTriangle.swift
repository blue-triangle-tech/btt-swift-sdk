//
//  BlueTriangle.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// The entry point for interacting with the Blue Triangle SDK.
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
        configuration.uploaderConfiguration.makeUploader(
            logger: logger,
            failureHandler: RequestFailureHandler(
                file: .requests,
                logger: logger))
    }()

    private static var timerFactory: (Page, BTTimer.TimerType) -> BTTimer = {
        configuration.timerConfiguration.makeTimerFactory(
            logger: logger,
            performanceMonitorFactory: configuration.makePerformanceMonitorFactory())
    }()

    private static var internalTimerFactory: () -> InternalTimer = {
        configuration.internalTimerConfiguration.makeTimerFactory(logger: logger)
    }()

    private static var shouldCaptureRequests: Bool = {
        .random(probability: configuration.networkSampleRate)
    }()

    /// A Boolean value indicating whether the SDK has been initialized.
    public private(set) static var initialized = false

    private static var crashReportManager: CrashReportManaging?

    private static var capturedRequestCollector: CapturedRequestCollecting? = {
        if shouldCaptureRequests {
            let collector = configuration.capturedRequestCollectorConfiguration.makeRequestCollector(
                logger: logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: CapturedRequestBuilder.makeBuilder { session },
                uploader: uploader)

            Task {
                await collector.configure()
            }
            return collector
        } else {
            return nil
        }
    }()

    private static var appEventObserver: AppEventObserver?

    /// Blue Triangle Technologies-assigned site ID.
    @objc public static var siteID: String {
        lock.sync { session.siteID }
    }

    /// Global User ID.
    @objc public static var globalUserID: Identifier {
        lock.sync { session.globalUserID }
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

    /// Boolean value indicating whether user is a returning visitor.
    @objc public static var isReturningVisitor: Bool {
        get {
            lock.sync { session.isReturningVisitor }
        }
        set {
            lock.sync { session.isReturningVisitor = newValue }
        }
    }

    /// A/B testing identifier.
    @objc public static var abTestID: String {
        get {
            lock.sync { session.abTestID }
        }
        set {
            lock.sync { session.abTestID = newValue }
        }
    }

    /// Legacy campaign name.
    @available(*, deprecated, message: "Use `campaignName` instead.")
    @objc public static var campaign: String? {
        get {
            lock.sync { session.campaign }
        }
        set {
            lock.sync { session.campaign = newValue }
        }
    }

    /// Campaign medium.
    @objc public static var campaignMedium: String {
        get {
            lock.sync { session.campaignMedium }
        }
        set {
            lock.sync { session.campaignMedium = newValue }
        }
    }

    /// Campaign name.
    @objc public static var campaignName: String {
        get {
            lock.sync { session.campaignName }
        }
        set {
            lock.sync { session.campaignName = newValue }
        }
    }

    /// Campaign source.
    @objc public static var campaignSource: String {
        get {
            lock.sync { session.campaignSource }
        }
        set {
            lock.sync { session.campaignSource = newValue }
        }
    }

    /// Data center.
    @objc public static var dataCenter: String {
        get {
            lock.sync { session.dataCenter }
        }
        set {
            lock.sync { session.dataCenter = newValue }
        }
    }

    /// Traffic segment.
    @objc public static var trafficSegmentName: String {
        get {
            lock.sync { session.trafficSegmentName }
        }
        set {
            lock.sync { session.trafficSegmentName = newValue }
        }
    }

    /// Custom metrics.
    public static var metrics: [String: AnyCodable]? {
        get {
            lock.sync { session.metrics }
        }
        set {
            lock.sync { session.metrics = newValue }
        }
    }

    /// Custom metrics.
    ///
    /// > Note: this member is provided for Objective-C compatibility; ``BlueTriangle/BlueTriangle/metrics``
    /// should be used when calling from Swift.
    @objc(metrics) public static var _metrics: [String: Any]? {
        get {
            lock.sync { session.metrics?.anyValues }
        }
        set {
            do {
                let converted = try newValue?.compactMapValues(AnyCodable.init)
                print("newValue: \(newValue) - converted: \(converted)")
                lock.sync { session.metrics = converted }
            } catch {
                logger.error(error.localizedDescription)
            }
        }
    }
}

// MARK: - Configuration
extension BlueTriangle {
    /// `configure` is a one-time configuration function to set session-level properties.
    /// - Parameter configure: A closure that enables mutation of the Blue Triangle SDK configuration.
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

    // We want to allow multiple configurations for testing
    internal static func reconfigure(
        configuration: BlueTriangleConfiguration = .init(),
        session: Session? = nil,
        logger: Logging? = nil,
        uploader: Uploading? = nil,
        timerFactory: ((Page, BTTimer.TimerType) -> BTTimer)? = nil,
        shouldCaptureRequests: Bool? = nil,
        internalTimerFactory: (() -> InternalTimer)? = nil,
        requestCollector: CapturedRequestCollecting? = nil
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
            if let shouldCaptureRequests = shouldCaptureRequests {
                self.shouldCaptureRequests = shouldCaptureRequests
            }
            if let internalTimerFactory = internalTimerFactory {
                self.internalTimerFactory = internalTimerFactory
            }
            self.capturedRequestCollector = requestCollector
        }
    }
}

// MARK: - Timer
public extension BlueTriangle {
    /// Creates a timer timer to measure the duration of a user interaction.
    ///
    /// The returned timer is not running. Call `start()` before passing to `endTimer(_:purchaseConfirmation:)`.
    ///
    /// - note: `configure(_:)` must be called before attempting to create a timer.
    ///
    /// - Parameters:
    ///   - page: An object providing information about the user interaction being timed.
    ///   - timerType: The type of timer.
    /// - Returns: The new timer.
    @objc
    static func makeTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        lock.lock()
        precondition(initialized, "BlueTriangle must be initialized before sending timers.")
        let timer = timerFactory(page, timerType)
        lock.unlock()
        return timer
    }

    /// Creates a running timer to measure the duration of a user interaction.
    ///
    /// - note: `configure(_:)` must be called before attempting to start a timer.
    ///
    /// - Parameters:
    ///   - page: An object providing information about the user interaction being timed.
    ///   - timerType: The type of timer.
    /// - Returns: The running timer.
    @objc
    static func startTimer(page: Page, timerType: BTTimer.TimerType = .main) -> BTTimer {
        let timer = makeTimer(page: page, timerType: timerType)
        timer.start()
        return timer
    }

    /// Ends a timer and upload it to Blue Triangle for processing.
    /// - Parameters:
    ///   - timer: The timer to upload.
    ///   - purchaseConfirmation: An object describing a purchase confirmation interaction.
    @objc
    static func endTimer(_ timer: BTTimer, purchaseConfirmation: PurchaseConfirmation? = nil) {
        timer.end()
        purchaseConfirmation?.orderTime = timer.endTime
        let request: Request
        lock.lock()
        do {
            request = try configuration.requestBuilder.builder(session, timer, purchaseConfirmation)
            lock.unlock()
        } catch {
            lock.unlock()
            logger.error(error.localizedDescription)
            return
        }
        uploader.send(request: request)
    }
}

// MARK: - Network Capture
public extension BlueTriangle {
    internal static func timerDidStart(_ type: BTTimer.TimerType, page: Page, startTime: TimeInterval) {
        guard case .main = type else {
            return
        }

        Task {
            await capturedRequestCollector?.start(page: page, startTime: startTime)
        }
    }

    /// Returns a timer for network capture.
    static func startRequestTimer() -> InternalTimer? {
        guard shouldCaptureRequests else {
            return nil
        }
        var timer = internalTimerFactory()
        timer.start()
        return timer
    }

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - data: The request response data.
    ///   - response: The request response.
    static func captureRequest(timer: InternalTimer, data: Data?, response: URLResponse?) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, response: response)
        }
    }

    /// Captures a network request.
    /// - Parameters:
    ///   - timer: The request timer.
    ///   - tuple: The asynchronously-delivered tuple containing the request contents as a Data instance and a URLResponse.
    static func captureRequest(timer: InternalTimer, tuple: (Data, URLResponse)) {
        Task {
            await capturedRequestCollector?.collect(timer: timer, response: tuple.1)
        }
    }

    /// Captures a network request.
    /// - Parameter metrics: An object encapsulating the metrics for a session task.
    static func captureRequest(metrics: URLSessionTaskMetrics) {
        Task {
            await capturedRequestCollector?.collect(metrics: metrics)
        }
    }
}

// MARK: - Crash Reporting
extension BlueTriangle {
    static func configureCrashTracking(with crashConfiguration: CrashReportConfiguration) {
        crashReportManager = CrashReportManager(crashConfiguration,
                                                logger: logger,
                                                uploader: uploader,
                                                sessionProvider: { session })
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
}
