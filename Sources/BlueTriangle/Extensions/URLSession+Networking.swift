//
//  URLSession+Networking.swift
//
//  Created by Mathew Gacy on 4/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLSession {
    static let live: Networking = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "\(Bundle.main.userAgentToken) \(Device.userAgentToken) \(Constants.sdkProductIdentifier)/\(BlueTriangle.version)"]

        let session = URLSession(configuration: configuration)
        return session.dataTaskPublisher
    }()
}
