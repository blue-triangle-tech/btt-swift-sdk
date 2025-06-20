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
                logger.info("Adding timer to open group.")
                openGroup.add(timer)
            } else {
                self.submitForceFully()
                logger.info("No open group — creating new group.")
                let newGroup = BTTimerGroup(logger: logger, onGroupCompleted: { [weak self] group in
                    self?.handleGroupCompletion(group)
                })
                activeGroups.append(newGroup)
                newGroup.add(timer)
            }
        }
    }
    
    func submitForceFully() {
        if let openGroup = activeGroups.last(where: { !$0.hasGroupSubmitted }), openGroup.isClosed {
            openGroup.forceEndAllTimers()
        }
    }
    
    func setGroupName(_ name: String) {
        if let openGroup = activeGroups.last(where: { !$0.isClosed }) {
            openGroup.setGroupName(name)
        }
    }

    private func handleGroupCompletion(_ group: BTTimerGroup) {
        group.submit()
        group.flush()
        activeGroups.removeAll { $0 === group }
    }
}
