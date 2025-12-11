//
//  Uploading.swift
//
//  Created by Mathew Gacy on 4/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol Uploading : Sendable {
    func send(request: Request)
}
