//
//  ErrorReport.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

struct ErrorReport: Codable {
    let message: String
    let eCnt: Int
    let eTp: String
    let ver: String
    let appName: String
    let line: Int
    let column: Int
    let time: Millisecond

    enum CodingKeys: String, CodingKey {
        case message = "msg"
        case eCnt
        case eTp
        case ver = "VER"
        case appName = "url"
        case line
        case column = "col"
        case time
    }
}

extension ErrorReport {
    init(
        error: Error,
        line: UInt,
        time: Millisecond
    ) {
        self.message = String(describing: error)
        self.eCnt = 1
        self.eTp = Constants.eTp
        self.ver = Version.number
        self.appName = Bundle.main.appName ?? "Unknown"
        self.line = Int(line)
        self.column = 1
        self.time = time
    }
}
