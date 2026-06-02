//
//  BTTimerGroupManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 28/05/25.
//

import Foundation

final class BTTimerGroupManager {
    private var activeGroups: [BTTimerGroup] = []
    private let logger: Logging
    private var lastTimerTime: Millisecond?
    private var lastActionTime = Date().timeIntervalSince1970.milliseconds
    private let lock = NSLock()

    init(logger: Logging) { self.logger = logger }

    func add(timer: BTTimer) {
        let pageName = timer.getPageName()
        
        let decision: (target: BTTimerGroup?, reason: String) = lock.sync {
            // First, try to find an open group
            if let open = activeGroups.last(where: { !$0.isClosed }) {
                lastTimerTime = timer.startTime.milliseconds
                return (open, "open group exists")
            }
            
            // If no open group, check if this page name exists in any recent group (not submitted)
            // Forcefully reuse that group even if closed
            if let recentGroup = activeGroups.reversed().first(where: { 
                !$0.hasGroupSubmitted && $0.containsPageName(pageName)
            }) {
                lastTimerTime = timer.startTime.milliseconds
                return (recentGroup, "matching page '\(pageName)' found in recent group")
            }
            
            lastTimerTime = timer.startTime.milliseconds
            return (nil, "no matching group found")
        }

        if let tg = decision.target {
            // Reopen the group if it was closed (to handle the case where it closed between checks)
            tg.reopenIfClosed()
            logger.info("Adding timer '\(pageName)' to existing group: \(decision.reason)")
            tg.add(timer)
        } else {
            logger.info("Creating new group for timer '\(pageName)': \(decision.reason)")
            let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
            let newGroup = startNewGroup(groupName: pageName, hasForcedGroup: false, cause: .timeout, causeInterval: interval)
            newGroup.add(timer)
        }
    }

    func startGroupIfNeeded(_ groupName : String) {
        let decision: (shouldStart: Bool, cause: GroupingCause?, lastTimerSnap: Millisecond?, matchingGroup: BTTimerGroup?) = lock.sync {
            // Check if there's an open group
            if let openGroup = activeGroups.last(where: { !$0.isClosed }) {
                return (false, nil, lastTimerTime, openGroup)
            }
            
            // Check if this page name exists in any recent group (not submitted yet)
            // If yes, reuse that group instead of creating a new one
            if let recentGroup = activeGroups.reversed().first(where: { 
                !$0.hasGroupSubmitted && $0.containsPageName(groupName)
            }) {
                return (false, nil, lastTimerTime, recentGroup)
            }
            
            // No open group and no matching page, so decide whether to start a new one
            if let lt = lastTimerTime, lt < lastActionTime {
                return (true, .tap, lastTimerTime, nil)
            }
            
            return (true, .timeout, lastTimerTime, nil)
        }
        
        if let matchingGroup = decision.matchingGroup {
            // Reopen the group if it was closed
            matchingGroup.reopenIfClosed()
            logger.info("Using existing group for '\(groupName)': page already exists in recent group")
            return
        }
        
        guard decision.shouldStart, let cause = decision.cause else {
            logger.info("Not starting group for '\(groupName)': no conditions met")
            return
        }
        
        logger.info("Starting new group for '\(groupName)': cause = \(cause.description)")
        let interval = computeCauseInterval(from: decision.lastTimerSnap)
        _ = startNewGroup(groupName: groupName, hasForcedGroup: false, cause: cause, causeInterval: interval)
    }

    func setNewGroup(_ newGroup: String) {
        let interval = computeCauseInterval(from: lock.sync { lastTimerTime })
        _ = startNewGroup(groupName: newGroup, hasForcedGroup: true,  cause: .manual, causeInterval: interval)
    }

    func setGroupName(_ groupName: String) {
        let open = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
        open?.setGroupName(groupName)
    }

    func refreshGroupName() {
        let open = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
        open?.refreshGroupName()
    }

    func setLastAction(_ time: Date) {
        if BlueTriangle.configuration.enableGroupingTapDetection {
            lock.sync { self.lastActionTime = time.timeIntervalSince1970.milliseconds }
        }
    }
    
    /// Call this when navigating away from a screen to ensure the current group is closed and submitted
    func closeCurrentGroup() {
        let currentGroup: BTTimerGroup? = lock.sync {
            activeGroups.last(where: { !$0.hasGroupSubmitted })
        }
        
        if let group = currentGroup {
            logger.info("Closing current group due to screen navigation")
            group.forcefullyEndAllTimers()
        } else {
            logger.info("No current group to close on screen navigation")
        }
    }
    
    /// Debug method to check group status
    func logGroupStatus() {
        lock.sync {
            logger.info("Active groups count: \(self.activeGroups.count)")
            for (index, group) in activeGroups.enumerated() {
                logger.info("  Group \(index): closed=\(group.isClosed), submitted=\(group.hasGroupSubmitted)")
            }
        }
    }

    // MARK: – Internals

    private func computeCauseInterval(from last: Millisecond?) -> Millisecond {
        guard let last = last else { return 0 }
        let now = Date().timeIntervalSince1970.milliseconds
        return max(0, now - last)
    }

    /// Starts a new group. No nested locks: we snapshot the open group under lock,
    /// act on it outside, then append the new group under lock.
    @discardableResult
    private func startNewGroup(groupName: String, hasForcedGroup: Bool, cause: GroupingCause? = nil, causeInterval: Millisecond) -> BTTimerGroup {
        let openSnap: BTTimerGroup? = lock.sync { activeGroups.last(where: { !$0.hasGroupSubmitted }) }
        if let open = openSnap {
            logger.info("Forcefully submitted open group")
            open.forcefullyEndAllTimers()
        }

        let newGroup = BTTimerGroup(
            logger: logger,
            groupName: groupName,
            hasForcedGroup: hasForcedGroup,
            cause: cause,
            causeInterval: causeInterval,
            onGroupCompleted: { [weak self] group in
                self?.handleGroupCompletion(group)
            }
        )

        lock.sync {
            lastTimerTime = nil
            activeGroups.append(newGroup)
        }
        return newGroup
    }

    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        lock.sync { activeGroups.removeAll { $0 === group } }
    }
}
