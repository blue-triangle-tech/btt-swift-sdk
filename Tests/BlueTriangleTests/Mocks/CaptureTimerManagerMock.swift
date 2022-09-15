//
//  CaptureTimerManagerMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

class CaptureTimerManagerMock: CaptureTimerManaging {
    var onStart: () -> Void
    var onCancel: () -> Void
    var handler: (() -> Void)?

    init(
        onStart: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        handler: @escaping () -> Void  = {}
    ) {
        self.onStart = onStart
        self.onCancel = onCancel
        self.handler = handler
    }

    func start() {
        onStart()
    }

    func cancel() {
        onCancel()
    }

    func fireTimer() {
        handler?()
    }
}
