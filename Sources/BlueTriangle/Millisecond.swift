//
//  Millisecond.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

public typealias Millisecond = Int64

extension Millisecond {
    static var minute: Self {
        60_000
    }

    static var hour: Self {
        .minute * 60
    }

    static var day: Self {
        .hour * 24
    }

    static var sessionTimeout: Self {
        minute * Self(Constants.sessionTimeoutInMinutes)
    }

    static var userTimeout: Self {
        day * Self(Constants.userSessionTimeoutInDays)
    }
}
