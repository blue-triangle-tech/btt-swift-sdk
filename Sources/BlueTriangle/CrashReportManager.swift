//
//  CrashReportManager.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final class CrashReportManager: CrashReportManaging {

    private let crashReportPersistence: CrashReportPersisting.Type

    private let logger: Logging

    private let uploader: Uploading

    private let sessionProvider: () -> Session

    private var startupTask: Task<Void, Error>?

    init(
        crashReportPersistence: CrashReportPersisting.Type = CrashReportPersistence.self,
        logger: Logging,
        uploader: Uploading,
        sessionProvider: @escaping () -> Session
    ) {
        self.crashReportPersistence = crashReportPersistence
        self.logger = logger
        self.uploader = uploader
        self.sessionProvider = sessionProvider
        self.startupTask = Task.delayed(byTimeInterval: Constants.startupDelay, priority: .utility) { [weak self] in
            guard let session = self?.sessionProvider() else {
                return
            }

            self?.uploadReports(session: session)
            self?.startupTask = nil
        }
    }

    func uploadReports(session: Session) {
        guard let crashReport = crashReportPersistence.read() else {
            return
        }

        // Update session to use values from when the app crashed
        var sessionCopy = session
        sessionCopy.sessionID = crashReport.sessionID

        do {
            try upload(session: session, report: crashReport.report)

            crashReportPersistence.clear()
        } catch {
            logger.error(error.localizedDescription)
        }
    }
}

// MARK: - Private
private extension CrashReportManager {
    func makeTimerRequest(session: Session, errorTime: Millisecond) throws -> Request {
        let page = Page(pageName: Constants.crashID, pageType: Device.name)
        let timer = PageTimeInterval(startTime: errorTime, interactiveTime: 0, pageTime: 0)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }

    func makeErrorReportRequest(session: Session, report: ErrorReport) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": Constants.crashID,
            "txnName": session.trafficSegmentName,
            "sessionID": String(session.sessionID),
            "pgTm": "0",
            "pageType": Device.name,
            "AB": session.abTestID,
            "DCTR": session.dataCenter,
            "CmpN": session.campaignName,
            "CmpM": session.campaignMedium,
            "CmpS": session.campaignSource,
            "os": Constants.os,
            "browser": Constants.browser,
            "browserVersion": Device.bvzn,
            "device": Constants.device
        ]

        return try Request(method: .post,
                           url: Constants.errorEndpoint,
                           parameters: params,
                           model: [report])
    }

    func upload(session: Session, report: ErrorReport) throws {
        let timerRequest = try makeTimerRequest(session: session,
                                                errorTime: report.time)
        uploader.send(request: timerRequest)

        let reportRequest = try makeErrorReportRequest(session: session,
                                                       report: report)
        uploader.send(request: reportRequest)
    }
}
