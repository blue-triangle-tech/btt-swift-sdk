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
        }
    }
    
    func startGroupIfNeeded() {
        lock.sync {
            guard activeGroups.last(where: { !$0.isClosed }) == nil else {
                return
            }
            self.startNewGroup()
        }
    }

    func setGroupName(_ name: String) {
        if let openGroup = activeGroups.last(where: { !$0.isClosed }) {
            openGroup.setGroupName(name)
        }
    }
    
    private func startNewGroup() {
        self.submitGroupForcefully()
        let newGroup = BTTimerGroup(logger: logger, onGroupCompleted: { [weak self] group in
            self?.handleGroupCompletion(group)
        })
        activeGroups.append(newGroup)
    }

    private func submitGroupForcefully() {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }), openGroup.isClosed {
            openGroup.forcefullyEndAllTimers()
        }
    }
    
    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        group.flush()
        activeGroups.removeAll { $0 === group }
    }
}
