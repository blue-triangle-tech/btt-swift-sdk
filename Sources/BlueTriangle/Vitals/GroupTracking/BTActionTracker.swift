//
//  BTActionTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//

import Foundation

final class BTActionTracker {
    
    private var isActive: Bool = true
    private var actions: [Action] = []
    private let lock = NSLock()
    
    var isActiveTracking: Bool {
        lock.sync { isActive }
    }
    
    func recordAction(_ action: String) {
        actions.append(Action(startTime: timeInMillisecond, endTime: timeInMillisecond, action: action))
    }
    
    func getActions() -> [Action] {
        return actions
    }
    
    func clearActions() {
        actions.removeAll()
    }
    
    func stopTracking() {
        isActive = false
    }
    
    func uploadActions(_ page : String, pageStartTime : Millisecond) {
        if !actions.isEmpty {
            print("Page Recorded Actions for page :\(page)")
            for action in actions {
                print("\(action.action)")
            }
        }
    }
    
    private var timeInMillisecond : Millisecond{
        Date().timeIntervalSince1970.milliseconds
    }
}

struct Action{
    let startTime: Millisecond
    let endTime: Millisecond
    let action: String
}
