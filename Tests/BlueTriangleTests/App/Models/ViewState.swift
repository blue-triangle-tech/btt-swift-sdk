//
//  ViewState.swift
//
//  Created by Mathew Gacy on 1/13/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

enum ViewState<T> {
    case empty
    case loading
    case loaded(T)
    case errror(Error)
}
