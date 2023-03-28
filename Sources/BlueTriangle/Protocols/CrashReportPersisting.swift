//
//  CrashReportPersisting.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

protocol CrashReportPersisting {
    static func read() -> CrashReport?
    static func clear()
}
