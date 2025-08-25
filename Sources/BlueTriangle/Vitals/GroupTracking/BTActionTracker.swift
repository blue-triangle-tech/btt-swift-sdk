//
//  BTActionTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//

import Foundation

final class BTActionTracker {
    
    private var actions: [UserAction] = []
    
    func recordAction(_ action: UserAction) {
        actions.append(action)
    }
    
    func uploadActions(_ page : String, pageStartTime : TimeInterval) async {
        if !actions.isEmpty {
            await BlueTriangle.startActionTimerRequest(page: Page(pageName: page), startTime: pageStartTime.milliseconds)
            for action in actions {
                print("\(action.actionType) - \(action.action)")
                await BlueTriangle.captureActionRequest(startTime: action.startTime, endTime: action.endTime + Constants.minPgTm, groupStartTime: pageStartTime.milliseconds, action: action)
            }
            await BlueTriangle.uploadActionViewCollectedRequests()
        }
    }
}

struct UserAction{
    let startTime: Millisecond
    let endTime: Millisecond
    let action: String
    let actionType: String
    
    init(action: String, actionType: String) {
        self.action = action
        self.actionType = actionType
        self.startTime = Date().timeIntervalSince1970.milliseconds
        self.endTime = Date().timeIntervalSince1970.milliseconds
    }
}
