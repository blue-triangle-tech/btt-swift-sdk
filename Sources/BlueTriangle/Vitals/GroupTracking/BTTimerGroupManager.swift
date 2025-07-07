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
                startNewGroup()
            }
            lastTimerTime = timer.startTime.milliseconds
        }
    }
    
    func startGroupIfNeeded() {
        lock.sync {
            guard activeGroups.last(where: { !$0.isClosed }) == nil else {
                if let lastTime = lastTimerTime, lastTime < self.lastActionTime {
                    self.startNewGroup()
                }
                return
            }
            self.startNewGroup()
        }
    }

    func setGroupName(_ name: String) {
        self.startNewGroup(name)
    }
    
    func setLastAction(_ time: Date) {
        self.lastActionTime = time.timeIntervalSince1970.milliseconds
    }
    
    private func startNewGroup(_ groupName : String? = nil) {
        self.submitGroupForcefully()
        let newGroup = BTTimerGroup(logger: logger, groupName: groupName, onGroupCompleted: { [weak self] group in
            self?.handleGroupCompletion(group)
        })
        lastTimerTime = nil
        activeGroups.append(newGroup)
    }

    private func submitGroupForcefully() {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted })/*, openGroup.isClosed*/ {
            print("Forecfully submitted")
            openGroup.forcefullyEndAllTimers()
        }
    }
    
    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        group.flush()
        activeGroups.removeAll { $0 === group }
    }
}
