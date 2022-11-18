//
//  String+LocalizedError.swift
//
//  Created by Mathew Gacy on 11/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// Easily throw generic errors with a text description.
extension String: LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
