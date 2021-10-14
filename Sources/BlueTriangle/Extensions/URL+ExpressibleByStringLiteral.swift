//
//  URL+ExpressibleByStringLiteral.swift
//
//  Created by Mathew Gacy on 10/12/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.

import Foundation

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        guard let url = URL(string: "\(value)") else {
            preconditionFailure("Invalid static URL string: \(value)")
        }
        self = url
    }
}
