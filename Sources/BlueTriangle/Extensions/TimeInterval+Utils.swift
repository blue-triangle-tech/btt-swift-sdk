//
//  TimeInterval+Utils.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension TimeInterval {

    var milliseconds: Millisecond {
        Millisecond((self*1000).rounded())
    }

    static var day: TimeInterval {
        86_400.0
    }
}
