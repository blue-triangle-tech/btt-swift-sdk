//
//  URLRequestConvertible.swift
//
//  Created by Mathew Gacy on 4/11/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}
