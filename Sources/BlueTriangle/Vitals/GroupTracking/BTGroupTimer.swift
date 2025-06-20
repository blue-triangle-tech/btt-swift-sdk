//
//  BTGroupTimer.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

final class BTTimerGroup {
    private var timers: [BTTimer] = []
    private var idleTimer: Timer?
    private var groupTimer:BTTimer
    private let logger: Logging
    private var isGroupClosed = false
    private var hasSubmitted = false
    private let lock = NSLock()
    private let onGroupCompleted: (BTTimerGroup) -> Void
    private(set) var groupName: String?
    
    var isClosed: Bool {
        lock.sync { isGroupClosed }
    }
    
    var hasGroupSubmitted: Bool {
        lock.sync { hasSubmitted }
    }
    
    init(logger: Logging, onGroupCompleted: @escaping (BTTimerGroup) -> Void) {
        self.logger = logger
        self.onGroupCompleted = onGroupCompleted
        self.groupTimer = BlueTriangle.startTimer(page: Page(pageName: "BTTGroupPage"))
    }

    func forceEndAllTimers() {
        for timer in timers where !timer.hasEnded {
            let prop = timer.nativeAppProperties
            timer.nativeAppProperties = NativeAppProperties(
                fullTime: timeInterval.milliseconds - prop.loadStartTime,
                loadTime: prop.loadTime,
                loadStartTime: prop.loadStartTime,
                loadEndTime: prop.loadEndTime,
                maxMainThreadUsage: prop.maxMainThreadUsage,
                viewType: prop.viewType,
                offline: prop.offline,
                wifi: prop.wifi,
                cellular: prop.cellular,
                ethernet: prop.ethernet,
                other: prop.other,
                netState: prop.netState,
                netStateSource: prop.netStateSource)
            timer.end()
        }
    }
    
    func setGroupName(_ name: String?) {
        self.groupName = name
    }
    
    func add(_ timer: BTTimer) {
        lock.sync {
            guard !isGroupClosed else {
                return
            }
            
            timers.append(timer)
            observe(timer)
            resetIdleTimer()
        }
    }
    
    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: BlueTriangle.configuration.groupingIdleTime, repeats: false) { [weak self] _ in
            self?.closeGroup()
        }
    }
    
    private func closeGroup() {
        lock.sync {
            guard !isGroupClosed else { return }
            
            logger.info("Group closed due to idle.")
            isGroupClosed = true
            idleTimer?.invalidate()
            trySubmitGroup()
        }
    }
    
    private func observe(_ timer: BTTimer) {
        timer.onEnd = { [weak self, weak timer] in
            guard let self = self, let timer = timer else { return }
            self.timerDidEnd(timer)
        }
    }
    
    private func timerDidEnd(_ timer: BTTimer) {
        lock.sync {
            trySubmitGroup()
        }
    }
    
    private func trySubmitGroup() {
        guard isGroupClosed, !hasSubmitted else { return }
        
        let allTimersEnded = timers.allSatisfy { $0.hasEnded }
        if allTimersEnded {
            hasSubmitted = true
            onGroupCompleted(self)
        }
    }
    
    func submit() {
        let timerCount = timers.count
        let fullTime = timeInterval.milliseconds - groupTimer.startTime.milliseconds
        var pgtm: Millisecond = 0
        var pages = [String]()
        var viewType: ViewType?
        
        for timer in timers {
            let calculatedLoadTime = max((timer.nativeAppProperties.loadTime), Constants.minPgTm)
            pgtm = pgtm + calculatedLoadTime
            pages.append(timer.page.pageName)
            viewType = timer.nativeAppProperties.viewType
        }
        
        let pageName : String =  groupName ?? self.lastPageName(from: pages)  + " Group"
        self.groupTimer.page.pageName = pageName
        let networkReport = self.groupTimer.networkReport
        let maxMainThreadTask = self.groupTimer.performanceReport?.maxMainThreadTask.milliseconds ?? 0
        
        self.groupTimer.nativeAppProperties = NativeAppProperties(
            fullTime: fullTime,
            loadTime: pgtm,
            loadStartTime: 0,
            loadEndTime: 0,
            maxMainThreadUsage: maxMainThreadTask,
            viewType: viewType,
            offline: networkReport?.offline ?? 0,
            wifi: networkReport?.wifi ?? 0,
            cellular: networkReport?.cellular ?? 0,
            ethernet: networkReport?.ethernet ?? 0,
            other: networkReport?.other ?? 0,
            netState: networkReport?.netState ?? "",
            netStateSource: networkReport?.netSource ?? "",
            childViews : pages)
        
        for timer in timers {
            self.submitTimer(groupTimer:self.groupTimer , timer: timer, group: pageName)
        }
        
        self.groupTimer.pageTimeBuilder = {
            return pgtm
        }
        
        BlueTriangle.endTimer(self.groupTimer)
        logger.info("Submitting group result: \(timerCount) timers with name: \(pageName)")
    }

    func submitTimer( groupTimer : BTTimer, timer: BTTimer, group : String) {
        let pageName =  self.firstPageName(from: timer.page.pageName)
        BlueTriangle.captureRequest(startTime: timer.nativeAppProperties.loadStartTime, endTime: timer.nativeAppProperties.loadEndTime, groupStartTime: groupTimer.startTime.milliseconds, response: CustomPageResponse(file: pageName, url: pageName, domain: group, pageName: group))
    }
    
    func flush() {
        timers.removeAll()
    }
}

extension BTTimerGroup {
    private func lastPageName(from titles: [String]) -> String {
        for title in titles.reversed() {
            if let part = title.components(separatedBy: "-").last,
               title.contains("-") {
                return part.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return titles.last ?? ""
    }
    
    private func firstPageName(from title: String) -> String {
        if let part = title.components(separatedBy: "-").first,
           title.contains("-") {
            return part.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
    }
    
    private var timeInterval : TimeInterval{
        Date().timeIntervalSince1970
    }
}


struct CustomPageResponse{
    let file: String?
    let url: String?
    let domain: String?
    let pageName: String?
}
