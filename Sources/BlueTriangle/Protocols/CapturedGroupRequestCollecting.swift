//
//  CapturedGroupRequestCollecting.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/06/25.
//

import Foundation

protocol CapturedGroupRequestCollecting: Actor {
    func start(page: Page, startTime: TimeInterval)
    func update(pageName : String, startTime: Millisecond)
    func collect(startTime : Millisecond, endTime: Millisecond, groupStartTime: Millisecond, response: CustomPageResponse)
}
