//
//  NumberFormatter+Ext.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import Foundation

extension NumberFormatter {
    static var decimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }

    static var integer: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        return formatter
    }
}
