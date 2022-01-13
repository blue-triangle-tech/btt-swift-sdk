//
//  ViewState.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 1/13/22.
//

import Foundation

enum ViewState<T> {
    case empty
    case loading
    case loaded(T)
    case errror(Error)
}
