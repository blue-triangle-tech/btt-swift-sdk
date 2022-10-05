//
//  TimerViewModel.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import BlueTriangle
import Foundation
import class UIKit.UIDevice

@MainActor
class TimerViewModel: ObservableObject {
    let siteID: String
    let globalUserID: String

    @Published var isReturningVisitor: Bool {
        didSet {
            BlueTriangle.isReturningVisitor = isReturningVisitor
        }
    }

    @Published var sessionID: String {
        didSet {
            BlueTriangle.sessionID = UInt64(sessionID) ?? 0
        }
    }

    @Published var abTestID: String {
        didSet {
            BlueTriangle.abTestID = abTestID
        }
    }

    @Published var campaignMedium: String {
        didSet {
            BlueTriangle.campaignMedium = campaignMedium
        }
    }

    @Published var campaignName: String {
        didSet {
            BlueTriangle.campaignName = campaignName
        }
    }

    @Published var campaignSource: String {
        didSet {
            BlueTriangle.campaignSource = campaignSource
        }
    }

    @Published var dataCenter: String {
        didSet {
            BlueTriangle.dataCenter = dataCenter
        }
    }

    @Published var trafficSegmentName: String {
        didSet {
            BlueTriangle.trafficSegmentName = trafficSegmentName
        }
    }

    @Published var timerFields: [String: String]?

    @Published var page = Page(pageName: "")

    @Published var showPurchaseConfirmation: Bool = false

    @Published var purchaseConfirmation = PurchaseConfirmation(cartValue: 0.0)

    var hasPendingTimer: Bool {
        btTimer != nil
    }

    private var btTimer: BTTimer? {
        didSet {
            objectWillChange.send()
        }
    }

    init() {
        self.siteID = BlueTriangle.siteID
        self.globalUserID = String(BlueTriangle.globalUserID)
        self.isReturningVisitor = BlueTriangle.isReturningVisitor
        self.sessionID = String(BlueTriangle.sessionID)
        self.abTestID = BlueTriangle.abTestID
        self.campaignMedium = BlueTriangle.campaignMedium
        self.campaignName = BlueTriangle.campaignName
        self.campaignSource = BlueTriangle.campaignSource
        self.dataCenter = BlueTriangle.dataCenter
        self.trafficSegmentName = BlueTriangle.trafficSegmentName
    }

    func submit() async {
        timerFields = await submitTimer()
    }

    func clear() {
        isReturningVisitor = false
        abTestID = "Default"
        campaignMedium = ""
        campaignName = ""
        campaignSource = ""
        dataCenter = "Default"
        trafficSegmentName = ""
        page = Page(pageName: "")
    }

    private func submitTimer() async -> [String: String]? {
        guard btTimer == nil else {
            return nil
        }

        let timer = BlueTriangle.makeTimer(page: page)

        btTimer = timer
        defer { btTimer = nil }

        timer.start()
        let task = Task { () -> [String: String]? in
            try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            try Task.checkCancellation()

            BlueTriangle.endTimer(
                timer,
                purchaseConfirmation: showPurchaseConfirmation ? purchaseConfirmation : nil)
            return requestRepresentation()
        }

        do {
            return try await task.value
        } catch {
            return nil
        }
    }
}

// MARK: - Request Representation
extension TimerViewModel {
    private enum RequestConstants {
        static let browser = "Native App"
        static let device = "Mobile"
        static let os = "iOS"
        static let wcd = 1
        static let eventType = 9
        static let navigationType = 9
    }

    private var appVersion: String {
        let versionNumber = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0"
        return "\(RequestConstants.browser)-\(versionNumber)-\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    func requestRepresentation() -> [String: String]? {
        var representation: [String: String] = [:]

        // Additional
        representation.represent(RequestConstants.browser, forKey: .browser)
        representation.represent(RequestConstants.device, forKey: .device)
        representation.represent(RequestConstants.os, forKey: .os)

        // Session
        representation.represent(isReturningVisitor.smallInt, forKey: .isReturningVisitor)
        representation.represent(RequestConstants.wcd, forKey: .wcd)
        representation.represent(RequestConstants.eventType, forKey: .eventType)
        representation.represent(RequestConstants.navigationType, forKey: .navigationType)
        representation.represent(UIDevice.current.systemName, forKey: .osInfo)
        representation.represent(appVersion, forKey: .appVersion)
        representation.represent(siteID, forKey: .siteID)
        representation.represent(UInt64(globalUserID) ?? 0, forKey: .globalUserID)
        representation.represent(UInt64(sessionID) ?? 0, forKey: .sessionID)
        representation.represent(abTestID, forKey: .abTestID)
        representation.represent(campaignMedium, forKey: .campaignMedium)
        representation.represent(campaignName, forKey: .campaignName)
        representation.represent(campaignSource, forKey: .campaignSource)
        representation.represent(dataCenter, forKey: .dataCenter)
        representation.represent(trafficSegmentName, forKey: .trafficSegmentName)

        // Page
        representation.represent(page.brandValue, forKey: .brandValue)
        representation.represent(page.pageName, forKey: .pageName)
        representation.represent(page.pageType, forKey: .pageType)
        representation.represent(page.referringURL, forKey: .referringURL)
        representation.represent(page.url, forKey: .url)

        // PurchaseConfirmation
        if showPurchaseConfirmation {
            representation.represent(purchaseConfirmation.cartValue, forKey: .cartValue)
            representation.represent(purchaseConfirmation.orderNumber, forKey: .orderNumber)
            representation.represent((purchaseConfirmation.orderTime * 1000).rounded(), forKey: .orderTime)
        }

        // Timer
        if let timer = btTimer {
            representation.represent(timer.startTime, forKey: .navigationStart)
            representation.represent(timer.startTime, forKey: .unloadEventStart)
            representation.represent(timer.interactiveTime, forKey: .domInteractive)
            representation.represent(timer.endTime - timer.startTime, forKey: .pageTime)
        }

        return representation
    }
}
