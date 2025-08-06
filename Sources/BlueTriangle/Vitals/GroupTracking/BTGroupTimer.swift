//
//  BTGroupTimer.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

final class BTTimerGroup {
    private var timers: [BTTimer] = []
    private var groupActions: [String] = []
    private var idleTimer: Timer?
    private var groupTimer:BTTimer
    private let logger: Logging
    private var isGroupClosed = false
    private var hasSubmitted = false
    private var hasForcedGroup = false
    private var groupName: String?
    private let lock = NSLock()
    private let onGroupCompleted: (BTTimerGroup) -> Void
    
    var isClosed: Bool {
        lock.sync { isGroupClosed }
    }
    
    var hasGroupSubmitted: Bool {
        lock.sync { hasSubmitted }
    }
    
    init(logger: Logging, groupName: String? = nil, onGroupCompleted: @escaping (BTTimerGroup) -> Void) {
        self.logger = logger
        self.hasForcedGroup = (groupName != nil) ? true : false
        self.onGroupCompleted = onGroupCompleted
        self.groupTimer = BlueTriangle.startTimer(page: Page(pageName: groupName ?? "BTTGroupPage"), isGroupedTimer: true)
    }

    func add(_ timer: BTTimer) {
        lock.sync {
            guard !isGroupClosed else { return }
            timers.append(timer)
            self.updatePageName()
            observe(timer)
            resetIdleTimer()
        }
    }
    
    func setGroupName(_ groupName: String) {
        self.groupName = groupName
        self.updatePageName()
    }
    
    func refreshGroupName() {
        self.updatePageName()
    }
    
    func setGroupActions(_ action: String) {
        self.groupActions.append(action)
    }
    
    func submit() {
        guard timers.count > 0 else {
            self.groupTimer.end()
            return
        }
        
        let timerCount = timers.count
        let fullTime = timeInterval.milliseconds - groupTimer.startTime.milliseconds
        let networkReport = self.groupTimer.networkReport
        let maxMainThreadTask = self.groupTimer.performanceReport?.maxMainThreadTask.milliseconds ?? 0
        var pgtm: Millisecond = 0
        var pages = [String]()
        var viewType: ViewType?
        
        for timer in timers {
            let calculatedLoadTime = max((timer.nativeAppProperties.loadTime), Constants.minPgTm)
            pgtm = pgtm + calculatedLoadTime
            pages.append(timer.page.pageName)
            viewType = timer.nativeAppProperties.viewType
        }
        
        //Setup group native app property
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
            grouped:true,
            netState: networkReport?.netState ?? "",
            netStateSource: networkReport?.netSource ?? "",
            childViews : pages.map { self.extractViewName(from: $0) })
        
        self.groupTimer.pageTimeBuilder = {
            return pgtm
        }
        
        BlueTriangle.endTimer(self.groupTimer)
        self.submitWcdRequests()
        logger.info("Submitting group result: \(timerCount) timers with name: \(self.groupTimer.page.pageName)")
    }
    
    func forcefullyEndAllTimers() {
        self.closeGroup()
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
                grouped:true,
                netState: prop.netState,
                netStateSource: prop.netStateSource)
            timer.end()
        }
    }

    func flush() {
        timers.removeAll()
    }
    
    private func trySubmitGroup() {
        guard isGroupClosed, !hasSubmitted else { return }
        let allTimersEnded = timers.allSatisfy { $0.hasEnded }
        if allTimersEnded {
            hasSubmitted = true
            isGroupClosed = true
            idleTimer?.invalidate()
            onGroupCompleted(self)
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
            self.updatePageName()
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
    
    private func updatePageName() {
        if !hasForcedGroup {
            var pages = [String]()
            for timer in timers {
                pages.append(timer.page.pageName)
            }
            let pageName : String =  self.groupName ?? self.extractLastPageName(from: pages)
            self.groupTimer.page.pageName = pageName
        }
        self.groupTimer.page.pageName = self.groupTimer.page.pageName + Constants.GROUP_SUFFIX
        BlueTriangle.updateCaptureRequest(pageName: self.groupTimer.page.pageName, startTime: groupTimer.startTime.milliseconds)
    }
    
    private func submitSingleRequest( groupTimer : BTTimer, timer: BTTimer, group : String) {
        let pageName =  self.extractViewName(from: timer.page.pageName)
        let loadStartTime = timer.nativeAppProperties.loadStartTime > 0 ? timer.nativeAppProperties.loadStartTime : timer.startTime.milliseconds
        let loadEndTime = timer.nativeAppProperties.loadEndTime > 0 ? timer.nativeAppProperties.loadEndTime : loadStartTime + Constants.minPgTm
        BlueTriangle.captureGroupRequest(startTime: loadStartTime,
                                    endTime: loadEndTime,
                                    groupStartTime: groupTimer.startTime.milliseconds,
                                    response: CustomPageResponse(file: pageName, url: pageName, domain: group))
    }
}

extension BTTimerGroup {
    private func extractLastPageName(from titles: [String]) -> String {
        for title in titles.reversed() {
            if let part = title.components(separatedBy: "-").last,
               title.contains("-") {
                return part.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return titles.last ?? ""
    }
    
    private func extractViewName(from title: String) -> String {
        if let part = title.components(separatedBy: "-").first,
           title.contains("-") {
            return part.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
    }
    
    private func submitWcdRequests() {
        self.logger.info("Added Group Actions : \(self.groupActions)")
        BlueTriangle.startGroupTimerRequest(page: Page(pageName: self.groupTimer.page.pageName), startTime: self.groupTimer.startTime)
        for timer in timers {
            self.submitSingleRequest(groupTimer:self.groupTimer , timer: timer, group: self.groupTimer.page.pageName)
        }
        BlueTriangle.uploadGroupedViewCollectedRequests()
    }
    
    private var timeInterval : TimeInterval{
        Date().timeIntervalSince1970
    }
}

struct CustomPageResponse{
    let file: String?
    let url: String?
    let domain: String?
}
