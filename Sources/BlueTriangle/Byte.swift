//
//  Byte.swift
//
//  Created by Mathew Gacy on 2/14/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

typealias Byte = UInt8

/// Adds control character conveniences.
extension Byte {
    /// {
    static let leftCurlyBracket: Byte = 0x7B

    /// }
    static let rightCurlyBracket: Byte = 0x7D
}
