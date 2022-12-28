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

    static func value(for key: Key) -> String {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key.rawValue) else {
            fatalError("Missing Configuration.Key: \(key.rawValue)")
        }
        guard let value = object as? String else {
            fatalError("Invalid Type for Configuration.Key \(key.rawValue)")
        }

        return value
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
