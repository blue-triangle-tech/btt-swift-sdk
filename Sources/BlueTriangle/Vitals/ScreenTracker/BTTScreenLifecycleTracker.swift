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
    func loadStarted(_ id : String, _ name : String, _ title : String, _ time : TimeInterval) async
    func loadFinish(_ id : String, _ name : String,_ title : String, _ time : TimeInterval) async
    func viewStart(_ id : String, _ name : String, _ title : String, _ time : TimeInterval) async
    func viewingEnd(_ id : String, _ name : String, _ title : String, _ time : TimeInterval) async
}

public actor BTTScreenLifecycleTracker : BTScreenLifecycleTracker {
    private var btTimeActivityrMap = [String: TimerMapActivity]()
    private var enableLifecycleTracker = false
    private var screenType = ScreenType.UIKit
    private(set) var logger : Logging?
    private var startTimerPages = [String : (name: String, title: String)]()
    private let lock = NSLock()
    
    internal init(_ logger : Logging? = nil, enableLifecycleTracker : Bool = false) {
        self.logger = logger
        self.enableLifecycleTracker = enableLifecycleTracker
        Task {
            await self.registerAppForegroundAndBackgroundNotification()
        }
    }
    
    func setLifecycleTracker(_ enable : Bool){
        lock.sync {
            self.enableLifecycleTracker = enable
        }
    }
    
    func setUpScreenType(_ type : ScreenType){
        lock.sync {
            self.screenType = type
        }
    }
    
    func loadStarted(_ id: String, _ name: String, _ title : String = "", _ time : TimeInterval = Date().timeIntervalSince1970)  async{
        NSLog("Task--: \(name) Task loaded 3 -\(time)")
        await self.manageTimer(name, id: id, type: .load, title: title, time)
    }
    
    func loadFinish(_ id: String, _ name: String, _ title : String = "", _ time : TimeInterval = Date().timeIntervalSince1970)  async{
        await self.manageTimer(name, id: id, type: .finish, title: title, time)
    }
    
    func viewStart(_ id: String, _ name: String, _ title : String = "", _ time : TimeInterval = Date().timeIntervalSince1970)  async{
        await self.manageTimer(name, id: id, type: .view, title: title, time)
    }
    
    func viewingEnd(_ id: String, _ name: String, _ title : String = "", _ time : TimeInterval = Date().timeIntervalSince1970)  async {
        await self.manageTimer(name, id: id, type: .disappear, title: title, time)
    }
    
    func manageTimer(_ pageName : String, id : String, type : TimerMapType, title : String = "", _ time : TimeInterval = Date().timeIntervalSince1970) async {
        guard self.getEnableLifecycleTracker() else { return }
        let timerActivity = await self.getTimerActivity(pageName, id: id, pageTitle: title, time: time)
        self.setTimeActivity(timerActivity, for: id)
        await timerActivity.manageTimeFor(type: type, time)
        if type == .disappear{
            self.removeTimeActivity(for: id)
        }
        else if (type == .load || type == .view){
            SignalHandler.setCurrentPageName(pageName)
        }
    }
    
    private func getEnableLifecycleTracker() -> Bool {
        lock.sync {
            enableLifecycleTracker
        }
    }
    
    private func getTimeActivity(for id: String) -> TimerMapActivity? {
        lock.sync {
            btTimeActivityrMap[id]
        }
    }

    private func setTimeActivity(_ activity: TimerMapActivity, for id: String) {
        lock.sync {
            btTimeActivityrMap[id] = activity
        }
    }
    
    private func getAllActivities() -> [(key: String, value: TimerMapActivity)] {
        lock.sync {
            btTimeActivityrMap.map { ($0.key, $0.value) }
        }
    }

    private func removeTimeActivity(for id: String) {
        lock.sync {
            btTimeActivityrMap.removeValue(forKey: id)
        }
    }
    
    private func removeAllTimeActivity() {
        lock.sync {
            btTimeActivityrMap.removeAll()
        }
    }
    
    private func getStartPage(for id: String) -> (name: String, title: String)? {
        lock.sync {
            startTimerPages[id]
        }
    }

    private func setStartTimePage(_ page: (name: String, title: String), for id: String) {
        lock.sync {
            startTimerPages[id] = page
        }
    }

    private func removeAllStartTimePages() {
        lock.sync {
            startTimerPages.removeAll()
        }
    }

    private func getAllStartTimePages() -> [(key: String, value: (name: String, title: String))] {
        lock.sync {
            Array(startTimerPages.map { ($0.key, $0.value) })
        }
    }
    
    private func getTimerActivity(_ pageName : String, id : String, pageTitle : String = "", time : TimeInterval) async -> TimerMapActivity{
        if let btTimerActivity =  getTimeActivity(for: id) {
            await btTimerActivity.setPageName(pageName,title: pageTitle)
            return btTimerActivity
        }else {
            let timerActivity = await TimerMapActivity(pageName: pageName, screenType: self.screenType, logger: logger, pageTitle: pageTitle, time: time)
            return timerActivity
        }
    }
    
#if os(iOS)
    private var bgObserver: NSObjectProtocol?
    private var fgObserver: NSObjectProtocol?
    private var bgTask: Task<Void, Never>?
    private var fgTask: Task<Void, Never>?
#endif
    
    func registerAppForegroundAndBackgroundNotification() {
#if os(iOS)
            let center = NotificationCenter.default
            
            if #available(iOS 15, *) {
                bgTask = Task { [weak self] in
                    guard let self else { return }
                    for await _ in center.notifications(named: UIApplication.didEnterBackgroundNotification) {
                        await self.appMovedToBackground()
                    }
                }
                
                fgTask = Task { [weak self] in
                    guard let self else { return }
                    for await _ in center.notifications(named: UIApplication.willEnterForegroundNotification) {
                        await self.appMovedToForeground()
                    }
                }
                
            } else {
                bgObserver = center.addObserver(
                    forName: UIApplication.didEnterBackgroundNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { await self?.appMovedToBackground() }
                }
                
                fgObserver = center.addObserver(
                    forName: UIApplication.willEnterForegroundNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    Task { await self?.appMovedToForeground() }
                }
            }
#endif
    }
    
    private func stopActiveTimersWhenAppWentToBackground() async {
        guard self.getEnableLifecycleTracker() else { return }
        for (key, activity) in getAllActivities() {
            let page = await activity.getPageName()
            let title = await activity.getTitleName()
            self.setStartTimePage((page, title), for: key)
            await viewingEnd(key, page, title)
        }
        self.removeAllTimeActivity()
        logger?.info("Stop active timer when app went to background")
    }

    private func startInactiveTimersWhenAppCameToForeground() async {
        guard self.getEnableLifecycleTracker() else { return }
        for (key, page) in getAllStartTimePages() {
            await viewStart(key, page.name, page.title)
        }
        self.removeAllStartTimePages()
        logger?.info("Start active timer when app come to foreground")
    }
    
    @objc private func appMovedToBackground() async {
        Task {
            await BlueTriangle.getScreenTracker()?.stopActiveTimersWhenAppWentToBackground()
        }
    }
    
    @objc private func appMovedToForeground() async {
        Task {
            await BlueTriangle.getScreenTracker()?.startInactiveTimersWhenAppCameToForeground()
        }
    }
    
    func unregisterAppForegroundAndBackgroundNotification() {
#if os(iOS)
        bgTask?.cancel()
        fgTask?.cancel()
        bgTask = nil
        fgTask = nil
        
        if let bgObserver {
            NotificationCenter.default.removeObserver(bgObserver)
            self.bgObserver = nil
        }
        if let fgObserver {
            NotificationCenter.default.removeObserver(fgObserver)
            self.fgObserver = nil
        }
        
#endif
    }
    
    @MainActor
     func stop() {
         Task {
#if os(iOS)
             UIViewController.removeSetUp()
             await self.unregisterAppForegroundAndBackgroundNotification()
#endif
         }
    }
}

enum TimerMapType: @unchecked Sendable{
  case load, finish, view, disappear
}

actor TimerMapActivity {
    
    private let timer : BTTimer
    private let screenType : ScreenType
    private var loadTime : Millisecond?
    private var willViewTime : Millisecond?
    private var viewTime : Millisecond?
    private var disapearTime : Millisecond?
    private var confidenceRate : Int32? = 100
    private var confidenceMsg : String? = ""
    private(set) var logger : Logging?
    private let maxPGTMTime : Millisecond = 20_000
    
    init(pageName: String, screenType : ScreenType, logger : Logging?, pageTitle : String = "", time: TimeInterval) async {
        self.screenType = screenType
        self.logger = logger
        
        if BlueTriangle.configuration.enableGrouping {
            await BlueTriangle.startGroupIfNeeded(time)
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName, pageTitle: pageTitle), timerType: .custom, isGroupedTimer: true)
        } else {
            self.timer = BlueTriangle.startTimer(page:Page(pageName: pageName))
        }
    }
    
    func setPageName(_ pageName : String, title: String){
        if timer.isGroupTimer {
            self.timer.setPageName(pageName)
            self.timer.setPageTitle(title)
        }
    }
    
    func manageTimeFor(type: TimerMapType, _ time : TimeInterval) async {
        let timeInMilliseconds  = time.milliseconds
        switch type {
        case .load:
            await setLoadTime(timeInMilliseconds)
        case .finish:
            if loadTime == nil {await setLoadTime(timeInMilliseconds) }
            await setWillViewTime(timeInMilliseconds)
        case .view:
            if loadTime == nil {await setLoadTime(timeInMilliseconds) }
            await setViewTime(timeInMilliseconds)
        case .disappear:
            await evaluateConfidence()
            await setDisappearTime(timeInMilliseconds)
        }
    }
    
    private func setLoadTime(_ time : Millisecond) async{
        await self.submitTimerOfType(.load)
        self.loadTime = time
        await BlueTriangle.computeNameOfTheGroup()
    }
    
    private func setWillViewTime(_ time : Millisecond) async{
        self.willViewTime = time
        await BlueTriangle.computeNameOfTheGroup()
    }
    
    private func setViewTime(_ time : Millisecond) async{
        self.viewTime = time
        await self.submitTimerOfType(.view)
        await BlueTriangle.computeNameOfTheGroup()
    }
    
    private func setDisappearTime(_ time : Millisecond) async{
        self.disapearTime = time
        await self.submitTimerOfType(.disappear)
        await BlueTriangle.computeNameOfTheGroup()
    }
    
    private func evaluateConfidence() async {
        switch (loadTime, willViewTime, viewTime) {
        case let (_, willView?, nil):
            await self.setViewTime(willView)
            confidenceRate = 50
            confidenceMsg = "viewDidAppear tracking information is missing."
            
        case let (load?, nil, view?):
            let timeGap = view - load
            if timeGap >= maxPGTMTime {
                confidenceRate = 50
                confidenceMsg = "viewDidLoad tracking correct information is missing."
            }else {
                confidenceRate = 100
                confidenceMsg = ""
            }
            
        case  let (load?, willView?, _):
            let timeGap = (willView - load)
            if timeGap >= maxPGTMTime {
                self.loadTime = willView
                confidenceRate = 50
                confidenceMsg = "viewDidLoad tracking correct information are missing."
            } else {
                confidenceRate = 100
                confidenceMsg = ""
            }
        case (nil, nil, nil):
            confidenceRate = 0
            confidenceMsg = "Lifecycle tracking information are missing"
            await self.setLoadTime(timeInMillisecond - 15)
            await self.setViewTime(timeInMillisecond)
            
        case (nil, _, _):
            confidenceRate = 100
            confidenceMsg = ""
            
        default:
            confidenceRate = 0
            confidenceMsg = "Lifecycle tracking information are missing"
        }
    }

    func getPageName()-> String {
        return self.timer.getPageName()
    }
    
    func getTitleName()-> String {
        return self.timer.getPageTitle()
    }
    
    private func submitTimerOfType(_ type : TimerMapType) async {
        if isGroupedANDAutoTracked {
            if type == .load {
                print("Added timer : \(timer.getPageName())")
                await BlueTriangle.addGroupTimer(timer)
            }
            if type == .view {
                if let viewTime = viewTime, let loadTime = loadTime {
                    await self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: timeInMillisecond)
                }
            } else {
                if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
                    await self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
                    if timer.isGroupTimer {
                        timer.end()
                    } else {
                        //Submit timer when switch from non group to group
                        await submitTimer()
                    }
                } else if type == .disappear {
                    timer.end()
                }
            }
        } else {
            if type == .disappear {
                await submitTimer()
            }
        }
    }
    
    private func submitTimer() async {
        if let viewTime = viewTime, let loadTime = loadTime, let disapearTime = disapearTime {
            await self.updateTrackingTimer(loadTime: loadTime, viewTime: viewTime, disapearTime: disapearTime)
            BlueTriangle.endTimer(timer)
            let pageInfoMessage = "View tracker timer submited for screen :\(self.timer.getPageName())"
            self.logger?.info(pageInfoMessage)
        } else {
            self.timer.end()
        }
    }

    private func updateTrackingTimer(loadTime: Millisecond, viewTime: Millisecond, disapearTime: Millisecond) async {
         //When "pgtm" is zero then fallback mechanism triggered that calculate performence time as screen time automatically. So to avoiding "pgtm" zero value setting default value 15 milliseconds.
         // Default "pgtm" should be minimum 0.01 sec (15 milliseconds). Because timer is not reflecting on dot chat bellow to that interval.
        let calculatedLoadTime = min(max(viewTime - loadTime, Constants.minPgTm), maxPGTMTime)
        
        let networkReport = await timer.getNetworkReport()

        timer.pageTimeBuilder = {
            return calculatedLoadTime
        }
        
        timer.trafficSegmentName = Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT
        
        timer.nativeAppProperties = await NativeAppProperties.make(
            fullTime: disapearTime - loadTime,
            loadTime: calculatedLoadTime,
            loadStartTime: loadTime,
            loadEndTime: viewTime,
            maxMainThreadUsage: timer.performanceReport?.maxMainThreadTask.milliseconds ?? 0,
            screenType: self.screenType,
            offline: networkReport?.offline ?? 0,
            wifi: networkReport?.wifi ?? 0,
            cellular: networkReport?.cellular ?? 0,
            ethernet: networkReport?.ethernet ?? 0,
            other: networkReport?.other ?? 0,
            confidenceRate: self.confidenceRate,
            confidenceMsg: self.confidenceMsg
        )
    }
    
    private var isGroupedANDAutoTracked : Bool {
        BlueTriangle.configuration.enableGrouping
    }
    
    private var timeInMillisecond : Millisecond{
        Date().timeIntervalSince1970.milliseconds
    }
}
