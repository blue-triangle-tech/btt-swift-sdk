//
//  URLSession+Networking.swift
//
//  Created by Mathew Gacy on 4/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLSession {
    static var live: Networking {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        return session.dataTaskPublisher
    }
}
