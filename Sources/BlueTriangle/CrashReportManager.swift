//
//  CrashReportManager.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

protocol CrashReportManaging {
    func uploadReports(session: Session)
}

enum CrashReportConfiguration {
    case nsException
}

class CrashReportManager: CrashReportManaging {

    private let logger: Logging

    private let uploader: Uploading

    init(
        _ configuration: CrashReportConfiguration,
        logger: Logging,
        uploader: Uploading
    ) {
        self.logger = logger
        self.uploader = uploader
        configureErrorHandling(configuration: configuration)
    }

    func uploadReports(session: Session) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let crashReport = CrashReportPersistence.read() else {
                return
            }
            do {
                guard let strongSelf = self else {
                    return
                }

                let timerRequest = try strongSelf.makeTimerRequest(session: session,
                                                                   crashTime: crashReport.time)
                strongSelf.uploader.send(request: timerRequest)

                let reportRequest = try strongSelf.makeCrashReportRequest(session: session,
                                                                          crashReport: crashReport)
                strongSelf.uploader.send(request: reportRequest)

                CrashReportPersistence.clear()
            } catch {
                self?.logger.error(error.localizedDescription)
            }
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
        let page = Page(deviceName: Device.name)
        let timer = PageTimeInterval(startTime: crashTime, interactiveTime: 0, pageTime: 0)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }

    private func makeCrashReportRequest(session: Session, crashReport: CrashReport) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(crashReport.time),
            "pageName": "\(Constants.crashID)-\(Device.name)",
            "txnName": session.trafficSegmentName,
            "sessionID": String(session.sessionID),
            "pgTm": "0",
            "pageType": Device.name,
            "AB": session.abTestID,
            "DCTR": session.dataCenter,
            "CmpN": session.campaignName,
            "CmpM": session.campaignMedium,
            "CmpS": session.campaignSource,
            "os": Constants.osParameter,
            "browser": Constants.browserName,
            "device": Constants.deviceParameter
        ]

        return try Request(method: .post,
                           url: Constants.errorEndpoint,
                           parameters: params,
                           model: [crashReport])
    }
}
