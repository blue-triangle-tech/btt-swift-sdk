//
//  Service+BTT.swift
//
//  Created by Mathew Gacy on 11/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

extension Service {
    static var captured: Self {
        let session = URLSession(configuration: .default)

        return .init(
            baseURL: URL(string: "https://\(Secrets.baseURL)")!,
            networking: { request in
                try await ResponseValue(session.btData(for: request))
            })
    }
}
