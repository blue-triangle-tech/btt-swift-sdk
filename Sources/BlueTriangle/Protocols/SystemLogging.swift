//
//  SystemLogging.swift
//
//  Created by Mathew Gacy on 4/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import os.log

protocol SystemLogging {
    func log(
        level: OSLogType,
        message: @escaping () -> String,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}
