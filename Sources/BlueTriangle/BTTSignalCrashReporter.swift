//
//  BTCrashReporter.swift
//  
//
//  Created by Ashok Singh on 01/07/24.
//

import UIKit

class BTTSignalCrashReporter {
    
    //Given Crash Directory
    private let  directory : String
    
    private let logger: Logging

    private let uploader: Uploading

    private let sessionProvider: () -> Session

    private let intervalProvider: () -> TimeInterval

    private var startupTask: Task<Void, Error>?

    init(
        directory: String = File.cacheRequestsFolder?.url.path ?? "",
        logger: Logging,
        uploader: Uploading,
        sessionProvider: @escaping () -> Session,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.directory = directory
        self.logger = logger
        self.uploader = uploader
        self.sessionProvider = sessionProvider
        self.intervalProvider = intervalProvider
    }
    
    func startUploadingSignalCrashes(){
        do{
            let session = self.sessionProvider()
            let crashes = try self.getAllCrashes()
            for crash in crashes {
                 uploadSignalCrash(crash, session)
            }
        }catch{
            logger.error(error.localizedDescription)
        }
    }
    
    private func uploadSignalCrash(_ crash: BTTCrash, _ session: Session) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }
                
                if let sessionId = UInt64(crash.btt_session_id){
                    var sessionCopy = session
                    sessionCopy.sessionID = sessionId
                    let pageName = crash.btt_page_name.count > 0 ? crash.btt_page_name : Constants.crashID
                    let message = """
                App crashed signal \(crash.signo) \(crash.signal)
                errno : \(crash.errno)
                signal code : \(crash.sig_code)
                exit value : \(crash.exit_value)
                """
                    
                    let exception = NSException(name: NSExceptionName("NSRangeException"), reason: message)
                    let crashReport = CrashReport(sessionID: sessionId, exception: exception, pageName: pageName, intervalProvider: TimeInterval(crash.crash_time))
                    try strongSelf.upload(session: sessionCopy, report: crashReport.report, pageName: crashReport.pageName)
                    try strongSelf.removeFile(crash)
                }
            }catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }
}

// MARK: - Private
private extension BTTSignalCrashReporter {
    func makeTimerRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let page = Page(pageName: pageName ?? Constants.crashID, pageType: Device.name)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        let nativeProperty =  report.nativeApp.copy(.Regular)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 nativeAppProperties: nativeProperty,
                                 isErrorTimer: true)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }

    func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? Constants.crashID,
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

    func upload(session: Session, report: ErrorReport, pageName : String?) throws {
        let timerRequest = try self.makeTimerRequest(session: session,
                                                     report: report, pageName: pageName)
        self.uploader.send(request: timerRequest)
        
        let reportRequest = try self.makeErrorReportRequest(session: session,
                                                            report: report, pageName: pageName)
        self.uploader.send(request: reportRequest)
    }
}

extension BTTSignalCrashReporter{
    
    // Parse given file to BTTCrash
    private func readFile(_ fileName : String) throws -> BTTCrash?{
        let decoder = JSONDecoder()
        let url = URL(fileURLWithPath: self.directory)
        let file = File.init(directory: url, name: fileName)
        let persistence = Persistence.init(file: file)
        let data : Data
        print(file.url.absoluteString)
        
        if let fileData = try persistence.readData(){
            data = fileData
        }else{
            data = Data()
        }
        
        return try decoder.decode(BTTCrash.self, from: data)
    }
    
    // Get All BTTCrash form files
    
    private  func getAllCrashes() throws -> [BTTCrash]{
        
        var crashes = [BTTCrash]()
        let files = try self.getAllFiles()
        
        for file in files {
            guard let crashData = try self.readFile(file) else { return crashes}
            crashes.append(crashData)
        }
        
        return crashes
    }
    
    // Fetch All .bttcrash files from given directory
    private  func getAllFiles() throws -> [String]{
        
        var fileList = [String]()
        let directory = self.directory
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath:directory).filter({ name in return name.contains(".bttcrash")}){
            fileList.append(contentsOf: files)
        }

        return fileList
    }
    
    private  func removeFile(_ crash : BTTCrash) throws{
        let url = URL(fileURLWithPath: self.directory)
        let file = File.init(directory: url, name: "\(crash.crash_time).bttcrash")
        let persistence = Persistence.init(file: file)
        try persistence.clear()
    }
}

struct BTTCrash: Codable {
    var signal: String
    var signo: Int
    var errno: Int
    var sig_code: Int
    var exit_value: Int
    var crash_time: UInt64
    var btt_session_id: String
    var btt_page_name: String
}
