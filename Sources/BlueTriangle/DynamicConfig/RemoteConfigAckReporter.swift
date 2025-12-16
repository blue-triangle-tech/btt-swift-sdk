//
//  RemoteConfigAckReporter.swift
//  
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class RemoteConfigAckReporter : @unchecked Sendable {

    private let queue = DispatchQueue(label: "com.bluetriangle.ack.reporter", qos: .userInitiated, autoreleaseFrequency: .workItem)
    
    private let logger: Logging
    private let uploader: Uploading
    
    init(logger: Logging, 
         uploader: Uploading) {
        
        self.logger = logger
        self.uploader = uploader
    }
    
    func reportSuccessAck(){
        Task {
            do {
                if let session = BlueTriangle.session() {
                    let pageName = "BTTConfigUpdate"
                    let pageGroup = "BTTConfigUpdate"
                    let trafficSegment = "BTTConfigUpdate"
                    try await self.upload(session: session,
                                    pageName: pageName,
                                    pageGroup: pageGroup,
                                    trafficSegment: trafficSegment)
                }
            }catch {
                self.logger.error("BlueTriangle:RemoteConfigAckReporter: Fail to upload success Ack -\(error.localizedDescription)")
            }
        }
    }
    
    func reportFailAck(_ error : String){
        Task {
            do {
                if let session = BlueTriangle.session(){
                    let pageName = "BTTConfigUpdate"
                    let pageGroup = "BTTConfigUpdate"
                    let trafficSegment = "BTTConfigUpdate"
                    let message = "\(BT_ErrorType.BTTConfigUpdateError.rawValue) : \(error)"
                    let nativeApp = await NativeAppProperties.nstEmpty
                    let crashReport = CrashReport(errorType : BT_ErrorType.BTTConfigUpdateError, sessionID: session.sessionID, message: message, pageName: pageName, nativeApp: nativeApp)
                    try await self.upload(session: session,
                                    report: crashReport.report,
                                    pageName: pageName,
                                    pageGroup: pageGroup,
                                    trafficSegment: trafficSegment)
                }
                
            }catch {
                self.logger.error("BlueTriangle:RemoteConfigAckReporter: Fail to upload fail Ack -\(error.localizedDescription)")
            }
        }
    }
}

private extension RemoteConfigAckReporter {
    func makeTimerRequest(session: Session, report: ErrorReport, pageName : String, pageGroup : String, trafficSegment : String) async throws -> Request {
        let page = Page(pageName: pageName, pageType: pageGroup)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        let nativeProperty =  await report.nativeApp.copy(.Regular)
        let customMetrics = session.customVarriables(logger: logger)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 customMetrics: customMetrics,
                                 trafficSegmentName: trafficSegment,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 nativeAppProperties: nativeProperty,
                                 isErrorTimer: true)
        
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
    
    func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String, pageGroup : String, trafficSegment : String) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName,
            "txnName": trafficSegment,
            "sessionID": String(session.sessionID),
            "pgTm": "0",
            "pageType": pageGroup,
            "AB": session.abTestID,
            "DCTR": session.dataCenter,
            "CmpN": session.campaignName,
            "CmpM": session.campaignMedium,
            "CmpS": session.campaignSource,
            "os": Constants.os,
            "browser": Constants.browser,
            "browserVersion": Device.current.bvzn,
            "device": Constants.device
        ]
        
        return try Request(method: .post,
                           url: Constants.errorEndpoint,
                           parameters: params,
                           model: [report])
    }
    
    func upload(session: Session, report: ErrorReport, pageName : String, pageGroup : String, trafficSegment : String) async throws {
        let timerRequest = try await makeTimerRequest(session: session,
                                                report: report, 
                                                pageName: pageName,
                                                pageGroup: pageGroup,
                                                trafficSegment: trafficSegment)
        uploader.send(request: timerRequest)
        
        let reportRequest = try makeErrorReportRequest(session: session,
                                                       report: report, 
                                                       pageName: pageName,
                                                       pageGroup: pageGroup,
                                                       trafficSegment: trafficSegment)
        uploader.send(request: reportRequest)
    }
}

private extension RemoteConfigAckReporter {
    
    func upload(session: Session, pageName : String, pageGroup : String, trafficSegment : String) async throws {
        
        let timeMS = Date().timeIntervalSince1970.milliseconds
        let durationMS = Constants.minPgTm
        let timerRequest = try await self.makeTimerRequest(session: session,
                                                           time: timeMS,
                                                           duration: durationMS,
                                                     pageName: pageName,
                                                     pageGroup: pageGroup,
                                                     trafficSegment: trafficSegment)
        self.uploader.send(request: timerRequest)
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, duration : Millisecond , pageName: String, pageGroup : String, trafficSegment : String) async throws -> Request {
        let page = Page(pageName: pageName, pageType: pageGroup)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        let customMetrics = session.customVarriables(logger: logger)
        let nativeAppProperties: NativeAppProperties = await .nstEmpty
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 customMetrics: customMetrics,
                                 trafficSegmentName: trafficSegment,
                                 nativeAppProperties: nativeAppProperties)
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
}
