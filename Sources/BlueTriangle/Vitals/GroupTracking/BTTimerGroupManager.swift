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
    
    init(logger: Logging) {
        self.logger = logger
    }

    func add(timer: BTTimer) {
        lock.sync {
            if let openGroup = activeGroups.last(where: { !$0.isClosed }) {
                openGroup.add(timer)
            } else {
                startNewGroup(cause:.timeoout)
            }
            lastTimerTime = timer.startTime.milliseconds
        }
    }
    
    func startGroupIfNeeded() {
        lock.sync {
            guard activeGroups.last(where: { !$0.isClosed }) == nil else {
                if let lastTimerTime = lastTimerTime, lastTimerTime < self.lastActionTime {
                    self.startNewGroup(cause: .tap)
                }
                return
            }
            self.startNewGroup(cause:.timeoout)
        }
    }

    func setNewGroup(_ newGroup: String) {
        self.startNewGroup(newGroup, cause: .manual)
    }
    
    func setGroupName(_ groupName: String) {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }) {
            openGroup.setGroupName(groupName)
        }
    }
    
    func recordAction(_ action: UserAction) {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }) {
            openGroup.recordActions(action)
        }
    }
    
    func refreshGroupName() {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }) {
            openGroup.refreshGroupName()
        }
    }
    
    func setLastAction(_ time: Date) {
        self.lastActionTime = time.timeIntervalSince1970.milliseconds
    }
    
    private var causeInterval: Millisecond {
        guard let lastTimerTime = lastTimerTime else { return 0 }
        return Date().timeIntervalSince1970.milliseconds - lastTimerTime
    }
    
    private func startNewGroup(_ groupName : String? = nil, cause: GroupingCause? = nil) {
        let causeInterval: Millisecond = self.causeInterval
        self.submitGroupForcefully()
        let newGroup = BTTimerGroup(logger: logger, groupName: groupName, cause: cause, causeInterval: causeInterval, onGroupCompleted: { [weak self] group in
            self?.handleGroupCompletion(group)
        })
        lastTimerTime = nil
        activeGroups.append(newGroup)
    }

    private func submitGroupForcefully() {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }){
            print("Forecfully submitted")
            openGroup.forcefullyEndAllTimers()
        }
    }
    
    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        activeGroups.removeAll { $0 === group }
    }
}
