//
//  CapturedActionRequestCollecting.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//

import Foundation

protocol CapturedActionRequestCollecting: Actor {
    func start(page: Page, startTime: Millisecond)
    func uploadCollectedRequests()
    func collect(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, action: UserAction) async
}
