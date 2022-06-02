//
//  TimeInterval+Utils.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension TimeInterval {
    var milliseconds: Millisecond {
        Millisecond((self * 1000).rounded())
    }

    var nanoseconds: UInt64 {
        UInt64(self * 1_000_000_000)
    }

    static var day: TimeInterval {
        86_400.0
    }
}
