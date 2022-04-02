//
//  CapturedRequestCollecting.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol CapturedRequestCollecting {
    func start(timer: BTTimer, upload: (BTTimer) -> Void)
    func makeTimer() -> InternalTimer? 
    func collect(timer: InternalTimer, data: Data?, response: URLResponse?)
}
