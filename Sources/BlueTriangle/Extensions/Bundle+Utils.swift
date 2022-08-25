//
//  Bundle+Utils.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension Bundle {
    /// The user-visible name for the bundle.
    var appName: String? {
        infoDictionary?["CFBundleDisplayName"] as? String ?? infoDictionary?["CFBundleName"] as? String
    }

    /// The release or version number of the bundle.
    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// The version of the build that identifies an iteration of the bundle.
    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    /// The User-Agent token.
    var userAgentToken: String {
        "\(appName ?? "Unknown")/\(releaseVersionNumber ?? "1.0")"
    }
}
