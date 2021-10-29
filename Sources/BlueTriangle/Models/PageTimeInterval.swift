//
//  PageTimeInterval.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct PageTimeInterval: Codable {
    let startTime: Millisecond
    let interactiveTime: Millisecond
    let pageTime: Millisecond

    var unloadStartTime: Millisecond {
        startTime
    }
}
