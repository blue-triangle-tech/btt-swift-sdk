//
//  AppError.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 11/15/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct AppError: Error {
    let reason: String
    let underlyingError: Error?
}
