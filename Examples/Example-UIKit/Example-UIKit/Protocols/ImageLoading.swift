//
//  ImageLoading.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import UIKit

typealias VoidCallback = @Sendable () async -> Void

protocol ImageLoading: Actor {
    func setCompletion(_ completion: VoidCallback?)
    func load(_ url: URL) async throws -> UIImage?
}
