//
//  Identifier.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

public typealias Identifier = UInt64

extension Identifier {
    private static let minID: Self = 100_000_000_000_000_000
    private static let maxID: Self = 999_999_999_999_999_999

    static func random() -> Self {
        Self.random(in: minID ... maxID)
    }
}
