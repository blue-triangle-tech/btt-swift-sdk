//
//  BTTScreenLifecycleTracker.swift
//
//
//  Created by JP on 13/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//


import Foundation


#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(AppEventLogger)
import AppEventLogger
#endif

protocol BTScreenLifecycleTracker{
    func loadStarted(_ id : String, _ name : String, isAutoTrack : Bool)
    func loadFinish(_ id : String, _ name : String, isAutoTrack : Bool)
    func viewStart(_ id : String, _ name : String, isAutoTrack : Bool)
    func viewingEnd(_ id : String, _ name : String, isAutoTrack : Bool)
}

public class BTTScreenLifecycleTracker : BTScreenLifecycleTracker{
    
    private var btTimeActivityrMap = [String: TimerMapActivity]()
    private var enableLifecycleTracker = false
    private var viewType = ViewType.UIKit
    private(set) var logger : Logging?
    private var startTimerPages = [String : String]()
    
    internal init() {
        registerAppForegroundAndBackgroundNotification()
    }
    
    func setUpLogger(_ logger : Logging){
        self.logger = logger
    }
    
    func setLifecycleTracker(_ enable : Bool){
        self.enableLifecycleTracker = enable
    }
    
    func setUpViewType(_ type : ViewType){
        self.viewType = type
    }
    
    func loadStarted(_ id: String, _ name: String, isAutoTrack : Bool = false) {
        self.manageTimer(name, id: id, type: .load, isAutoTrack: isAutoTrack)
    }
    
    func loadFinish(_ id: String, _ name: String, isAutoTrack : Bool = false) {
        self.manageTimer(name, id: id, type: .finish, isAutoTrack: isAutoTrack)
    }
    
    func viewStart(_ id: String, _ name: String, isAutoTrack : Bool = false) {
        self.manageTimer(name, id: id, type: .view, isAutoTrack: isAutoTrack)
    }
    
    func viewingEnd(_ id: String, _ name: String, isAutoTrack : Bool = false) {
        self.manageTimer(name, id: id, type: .disapear, isAutoTrack: isAutoTrack)
    }
    
    func manageTimer(_ pageName : String, id : String, type : TimerMapType, isAutoTrack : Bool = false){
        if self.enableLifecycleTracker{
            let timerActivity = getTimerActivity(pageName, id: id, isAutoTrack: isAutoTrack)
            btTimeActivityrMap[id] = timerActivity
            timerActivity.manageTimeFor(type: type)
            if type == .disapear{
                btTimeActivityrMap.removeValue(forKey: id)
            }
            else if (type == .load || type == .view){
                SignalHandler.setCurrentPageName(pageName)
            }
        }
    }
    
    private func getTimerActivity(_ pageName : String, id : String, isAutoTrack : Bool = false) -> TimerMapActivity{
        
        if let btTimerActivity = btTimeActivityrMap[id] {
            btTimerActivity.setPageName(pageName)
            return btTimerActivity
        }else{
            let timerActivity = TimerMapActivity(pageName: pageName, viewType: self.viewType, logger: logger, isAutoTrack: isAutoTrack)
            return timerActivity
        }
    }
    
    private func registerAppForegroundAndBackgroundNotification() {
#if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
#endif
    }
    
    private func stopActiveTimersWhenAppWentToBackground(){
        if self.enableLifecycleTracker{
            for key in  btTimeActivityrMap.keys{
                if let timerActivity = btTimeActivityrMap[key] {
                    let page = timerActivity.getPageName()
                    startTimerPages[key] = page
                    viewingEnd(key, page)
                }
            }
            
            self.logger?.info("Stop active timer when app went to background")
        }
    }

    private func startInactiveTimersWhenAppCameToForeground(){
        if self.enableLifecycleTracker{
            for key in  startTimerPages.keys{
                if let page = startTimerPages[key] {
                    viewStart(key, page)
                }
            }
            startTimerPages.removeAll()
            
            self.logger?.info("Start active timer when app come to foreground")
        }
    }
    
    @objc private func appMovedToBackground() {
        BlueTriangle.screenTracker?.stopActiveTimersWhenAppWentToBackground()
    }
    
    @objc private func appMovedToForeground() {
        BlueTriangle.screenTracker?.startInactiveTimersWhenAppCameToForeground()
    }
    
    func stop(){
#if os(iOS)
        UIViewController.removeSetUp()
        NotificationCenter.default.removeObserver(self)
#endif
    }
}

enum TimerMapType {
  case load, finish, view, disapear
}

class TimerMapActivity {
    
    private let timer : BTTimer
    private let isAutoTrack : Bool
    private var pageName : String
    private let viewType : ViewType
    private var loadTime : Millisecond?
    private var viewTime : Millisecond?
    private var disapearTime : Millisecond?
    private(set) var logger : Logging?
    
    init(pageName: String, viewType : ViewType, logger : Logging?, isAutoTrack: Bool = false) {
        self.pageName = pageName
        self.viewType = viewType
        self.logger = logger
        self.isAutoTrack = isAutoTrack
        
        if BlueTriangle.configuration.enableGrouping && isAutoTrack {
            BlueTriangle.groupTimer.startGroupIfNeeded()
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName), timerType: .custom, isGroupedTimer: true)
        } else {
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName))
        }
    }
    
    func setPageName(_ pageName : String){
        self.timer.page.pageName = pageName
        self.pageName = pageName
    }
    
    func getPageName()-> String {
        return pageName
    }
    
    func manageTimeFor(type : TimerMapType) {
        
        if type == .load {
            loadTime = timeInMilliseconds
            self.submitTimerOfType(.load)
        }
        else if type == .finish {
            if loadTime == nil {
                loadTime = timeInMilliseconds
                self.submitTimerOfType(.load)
            }
        }
        else if type == .view {
            viewTime = timeInMilliseconds
            self.submitTimerOfType(.view)
        }
        else if type == .disapear {
            if loadTime == nil {
                loadTime = self.timer.startTime.milliseconds
                let loginfo = "Load life cycle methods are not called for page :\(self.pageName)"
                self.logger?.info(loginfo)
                self.submitTimerOfType(.load)
            }
            if viewTime == nil {
                viewTime = (loadTime ?? self.timer.startTime.milliseconds) + Constants.minPgTm
                let loginfo = "View lifecycle methods are not called for page :\(self.pageName)"
                self.logger?.info(loginfo)
                self.submitTimerOfType(.view)
            }
            disapearTime = timeInMilliseconds
            self.submitTimerOfType(.disapear)
        }
    }
    
    private func submitTimerOfType(_ type : TimerMapType) {
        if isGroupedANDAutoTracked {
            if type == .load {
                BlueTriangle.groupTimer.add(timer: timer)
            }
            if type == .view {
                if let viewTime = viewTime, let loadTime = loadTime {
                    self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: timeInMilliseconds)
                }
            } else {
                if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
                    self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
                    timer.end()
                }
            }
        } else {
            submitTimer()
        }
    }
    
    private func submitTimer() {
        if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
            self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
            BlueTriangle.endTimer(timer)
            let pageInfoMessage = "View tracker timer submited for screen :\(self.pageName)"
            self.logger?.info(pageInfoMessage)
        } else {
            self.timer.end()
        }
    }

    private func updateTrackingTimer(loadTime: Millisecond, viewTime: Millisecond, disapearTime: Millisecond) {
         //When "pgtm" is zero then fallback mechanism triggered that calculate performence time as screen time automatically. So to avoiding "pgtm" zero value setting default value 15 milliseconds.
         // Default "pgtm" should be minimum 0.01 sec (15 milliseconds). Because timer is not reflecting on dot chat bellow to that interval.
        let calculatedLoadTime = max(viewTime - loadTime, Constants.minPgTm)
        let networkReport = timer.networkReport

        timer.pageTimeBuilder = {
            return calculatedLoadTime
        }
        
        timer.trafficSegmentName = Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT
        timer.nativeAppProperties = NativeAppProperties(
            fullTime: disapearTime - loadTime,
            loadTime: calculatedLoadTime,
            loadStartTime: loadTime,
            loadEndTime: viewTime,
            maxMainThreadUsage: timer.performanceReport?.maxMainThreadTask.milliseconds ?? 0,
            viewType: self.viewType,
            offline: networkReport?.offline ?? 0,
            wifi: networkReport?.wifi ?? 0,
            cellular: networkReport?.cellular ?? 0,
            ethernet: networkReport?.ethernet ?? 0,
            other: networkReport?.other ?? 0,
            netState: networkReport?.netState ?? "",
            netStateSource: networkReport?.netSource ?? ""
        )
    }
    
    private var timeInMilliseconds : Millisecond {
        Date().timeIntervalSince1970.milliseconds
    }
    
    private var isGroupedANDAutoTracked : Bool {
        BlueTriangle.configuration.enableGrouping && self.isAutoTrack
    }
}
