//
//  LaunchTimeReporter.swift
//  
//
//  Created by Ashok Singh on 08/05/24.
//

import Foundation
import Combine

class LaunchTimeReporter : ObservableObject {
    
    static let COLD_LAUNCH_PAGE_NAME = "ColdLaunchTime"
    static let HOT_LAUNCH_PAGE_NAME = "HotLaunchTime"
    static let LAUNCH_TIME_PAGE_GROUP = "LaunchTime"
    
    private var cancellables = Set<AnyCancellable>()
    private let launchMonitor = BlueTriangle.launchMonitor
    
    let session: Session
    let uploader: Uploading
    let logger: Logging
    
    init(session: Session,
         uploader: Uploading,
         logger: Logging ) {
        
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
    }

    func start(){
        
        launchMonitor.setUpLogger(logger)
        
        self.launchMonitor.launchEvents
            .sink { event in
                switch event {
                case .Cold(let date, let duration):
                    self.logger.info("Received cold launch at \(date)")
                    self.uploadReports(true, date, duration)
                case .Hot(let date, let duration):
                    self.logger.info("Received hot launch at \(date)")
                    self.uploadReports(false, date, duration)
                }
            }.store(in: &self.cancellables)
        
        logger.info("Setup to receive launch event")
    }
    
    private func uploadReports(_ isCold : Bool, _ time : Date, _ duration : TimeInterval) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }
                
                let pageName = isCold ? LaunchTimeReporter.COLD_LAUNCH_PAGE_NAME : LaunchTimeReporter.HOT_LAUNCH_PAGE_NAME
                let groupName = LaunchTimeReporter.LAUNCH_TIME_PAGE_GROUP
                let timeMS = time.timeIntervalSince1970.milliseconds
                let durationMS = duration.milliseconds
                
                let timerRequest = try strongSelf.makeTimerRequest(session: strongSelf.session,
                                                                   time: timeMS,
                                                                   duration: durationMS,
                                                                   pageName: pageName,
                                                                   pageGroup: groupName)
                strongSelf.uploader.send(request: timerRequest)
                strongSelf.logger.info("Uploaded successfully \(isCold ? "cold" : "hot") launch at \(time)")
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, duration : Millisecond , pageName: String, pageGroup : String) throws -> Request {
        let page = Page(pageName: pageName , pageType: pageGroup)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 nativeAppProperties: nil,
                                 isErrorTimer: false)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
}
