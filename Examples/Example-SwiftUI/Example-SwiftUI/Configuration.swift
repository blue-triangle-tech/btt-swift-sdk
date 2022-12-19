//
//  Configuration.swift
//
//  Created by Mathew Gacy on 12/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

private enum Configuration {
    enum Key: String {
        case baseURL = "_BASE_URL"
        case siteID = "_SITE_ID"
    }

    static func value<T>(for key: Key) -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key.rawValue) else {
            fatalError("Missing Configuration.Key: \(key.rawValue)")
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else {
                fallthrough
            }
            return value
        default:
            fatalError("Invalid Type for Configuration.Key \(key.rawValue): \(T.self)")
        }
    }
}

enum Secrets {
    static var baseURL: String {
        Configuration.value(for: .baseURL)
    }

    static var siteID: String {
        Configuration.value(for: .siteID)
    }
}
