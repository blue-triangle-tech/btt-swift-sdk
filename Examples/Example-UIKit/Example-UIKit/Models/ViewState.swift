//
//  ViewState.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

enum ViewState<T> {
    case empty
    case loading
    case loaded(T)
    case errror(Error)
}
