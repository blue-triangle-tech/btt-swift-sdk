//
//  Bool+Utils.swift
//
//  Created by Mathew Gacy on 2/17/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Bool {
    var smallInt: Int {
        Int(truncating: self)
    }
}
