//
//  BTGroupTimer.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

enum GroupingCause {
    case manual
    case timeoout
    case tap
    
    var description: String {
        switch self {
        case .manual:
            return "manual"
        case .timeoout:
            return "timeout"
        case .tap:
            return "tap"
        }
    }
}

final class BTTimerGroup {
    private var timers: Set<BTTimer> = []
    private var idleTimer: Timer?
    private var groupTimer:BTTimer
    private let logger: Logging
    private var isGroupClosed = false
    private var hasSubmitted = false
    private var hasForcedGroup = false
    private var groupName: String?
    private let lock = NSLock()
    private let onGroupCompleted: (BTTimerGroup) -> Void
    private let actionTracker = BTActionTracker()
    private var groupingCause: GroupingCause?
    private var causeInterval : Millisecond = 0
    
    var isClosed: Bool {
        lock.sync { isGroupClosed }
    }
    
    var hasGroupSubmitted: Bool {
        lock.sync { hasSubmitted }
    }
    
    init(logger: Logging, groupName: String? = nil, cause: GroupingCause? = nil, causeInterval: Millisecond = 0, onGroupCompleted: @escaping (BTTimerGroup) -> Void) {
        self.logger = logger
        self.hasForcedGroup = (groupName != nil) ? true : false
        self.onGroupCompleted = onGroupCompleted
        self.groupingCause = cause
        self.causeInterval = causeInterval
        self.groupTimer = BlueTriangle.startTimer(page: Page(pageName: groupName ?? "BTTGroupPage"), isGroupedTimer: true)
    }

    func add(_ timer: BTTimer) {
        lock.sync {
            guard !isGroupClosed else { return }
            timers.insert(timer)
            self.updatePageName()
            observe(timer)
            resetIdleTimer()
        }
    }
    
    func setGroupCause(_ cause: GroupingCause) {
        self.groupingCause = cause
    }
    
    func setGroupName(_ groupName: String) {
        self.groupName = groupName
        self.updatePageName()
    }
    
    func refreshGroupName() {
        self.updatePageName()
    }
    
    func recordActions(_ action: UserAction) {
        self.actionTracker.recordAction(action)
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
        var pgtmIntervals = [(Millisecond, Millisecond)]()
        
        for timer in timers {
            let calculatedLoadTime = max((timer.nativeAppProperties.loadTime), Constants.minPgTm)
            pgtm = pgtm + calculatedLoadTime
            pages.append(timer.page.pageName)
            viewType = timer.nativeAppProperties.viewType
            pgtmIntervals.append((timer.nativeAppProperties.loadStartTime, timer.nativeAppProperties.loadEndTime))
        }
        
        let unianOfpgTm = max(self.totalPgTmUnion(pgtmIntervals), Constants.minPgTm)
        
        logger.info("Unian pgTm of intervals \(pgtmIntervals): \(unianOfpgTm), Sum of pgTm : \(pgtm)")
        
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
            groupingCause: groupingCause?.description ,
            groupingCauseInterval: causeInterval,
            netState: networkReport?.netState ?? "",
            netStateSource: networkReport?.netSource ?? "",
            childViews : pages)
        
        self.groupTimer.pageTimeBuilder = {
            return unianOfpgTm
        }
        
        BlueTriangle.endTimer(self.groupTimer)
        self.submitChildsWcdRequests()
        self.submitActionsWcdRequests()
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
            var pages = [(String, String)]()
            for timer in timers {
                pages.append((timer.page.pageName, timer.page.pageTitle))
            }
            let pageName : String =  self.groupName ?? self.extractLastPageName(from: pages)
            self.groupTimer.page.pageName = pageName
        }
        self.groupTimer.trafficSegmentName = Constants.SCREEN_TRACKING_TRAFFIC_SEGMENT
        self.groupTimer.page.pageName = self.groupTimer.page.pageName + Constants.GROUP_SUFFIX
        BlueTriangle.updateCaptureRequest(pageName: self.groupTimer.page.pageName, startTime: groupTimer.startTime.milliseconds)
    }
    
    private func submitSingleRequest( groupTimer : BTTimer, timer: BTTimer, group : String) async {
        let pageName =  timer.page.pageName
        let loadStartTime = timer.nativeAppProperties.loadStartTime > 0 ? timer.nativeAppProperties.loadStartTime : timer.startTime.milliseconds
        let loadEndTime = timer.nativeAppProperties.loadEndTime > 0 ? timer.nativeAppProperties.loadEndTime : loadStartTime + Constants.minPgTm
        await BlueTriangle.captureGroupRequest(startTime: loadStartTime,
                                    endTime: loadEndTime,
                                    groupStartTime: groupTimer.startTime.milliseconds,
                                               response: CustomPageResponse(file: pageName, url: pageName, domain: group, native: timer.nativeAppProperties))
    }
}

extension BTTimerGroup {
    private func extractLastPageName(from titles: [(String, String)]) -> String {
        if let lastWithTitle = titles.last(where: { !$0.1.isEmpty }) {
            return lastWithTitle.1
        }
        return titles.last?.0 ?? ""
    }
    
    private func submitActionsWcdRequests() {
        Task {
            await actionTracker.uploadActions(self.groupTimer.page.pageName, pageStartTime: self.groupTimer.startTime)
        }
    }
        
    private func submitChildsWcdRequests() {
        Task {
            await BlueTriangle.startGroupTimerRequest(page: Page(pageName: self.groupTimer.page.pageName), startTime: self.groupTimer.startTime)
            for timer in timers {
                await self.submitSingleRequest(groupTimer:self.groupTimer , timer: timer, group: self.groupTimer.page.pageName)
            }
            await BlueTriangle.uploadGroupedViewCollectedRequests()
        }
    }
    
    private var timeInterval : TimeInterval{
        Date().timeIntervalSince1970
    }
    
    func totalPgTmUnion(_ intervals: [(Millisecond, Millisecond)]) -> Millisecond {
        guard !intervals.isEmpty else { return 0 }

        let sorted = intervals.sorted { $0.0 < $1.0 }
        var total : Millisecond = 0
        var (currentStart, currentEnd) = sorted[0]

        for (start, end) in sorted.dropFirst() {
            if start > currentEnd {
                total += currentEnd - currentStart
                currentStart = start
                currentEnd = end
            } else {
                currentEnd = max(currentEnd, end)
            }
        }

        total += currentEnd - currentStart
        return total
    }
}

struct CustomPageResponse{
    let file: String?
    let url: String?
    let domain: String?
    let native: NativeAppProperties?
}
