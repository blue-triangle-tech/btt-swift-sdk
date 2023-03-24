//
//  CrashReportManager.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

enum CrashReportConfiguration {
    case nsException
}

final class CrashReportManager: CrashReportManaging {

    private let logger: Logging

    private let uploader: Uploading

    private let sessionProvider: () -> Session

    private var startupTask: Task<Void, Error>?

    init(
        _ configuration: CrashReportConfiguration,
        logger: Logging,
        uploader: Uploading,
        sessionProvider: @escaping () -> Session
    ) {
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

        configureErrorHandling(configuration: configuration)
    }

    func uploadReports(session: Session) {
        guard let crashReport = CrashReportPersistence.read() else {
            return
        }
        do {
            let timerRequest = try makeTimerRequest(session: session,
                                                    crashTime: crashReport.time)
            uploader.send(request: timerRequest)

            let reportRequest = try makeCrashReportRequest(session: session,
                                                           crashReport: crashReport)
            uploader.send(request: reportRequest)

            CrashReportPersistence.clear()
        } catch {
            logger.error(error.localizedDescription)
        }
    }

    // MARK: - Private

    private func configureErrorHandling(configuration: CrashReportConfiguration) {
        switch configuration {
        case .nsException:
            configureNSExceptionHandler()
        }
    }

    private func configureNSExceptionHandler() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReportPersistence.save(exception)
        }
    }

    private func makeTimerRequest(session: Session, crashTime: Millisecond) throws -> Request {
        let page = Page(pageName: Constants.crashID, pageType: Device.name)
        let timer = PageTimeInterval(startTime: crashTime, interactiveTime: 0, pageTime: 0)
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

    private func makeCrashReportRequest(session: Session, crashReport: CrashReport) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(crashReport.time),
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
                           model: [crashReport])
    }
}
