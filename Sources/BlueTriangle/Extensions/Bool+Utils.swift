//
//  Bool+Utils.swift
//
//  Created by Mathew Gacy on 2/17/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Bool {
    static func random(probability: Double) -> Self {
        guard probability <= 1.0 else {
            return true
        }
        return Double.random(in: 0...1) <= probability
    }
}
