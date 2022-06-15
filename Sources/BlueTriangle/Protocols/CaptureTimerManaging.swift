//
//  CaptureTimerManaging.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol CaptureTimerManaging {
    var handler: (() -> Void)? { get set }

    func start()
    func cancel()
}
