//
//  URLSession+ResponseValue.swift
//
//  Created by Mathew Gacy on 10/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLSession {
    func data(request: URLRequest) async throws -> ResponseValue {
        try await ResponseValue(data(for: request))
    }
}
