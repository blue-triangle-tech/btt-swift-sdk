//
//  OperatingSystemVersion+Utils.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension OperatingSystemVersion {
    var osVersionShort: String {
        "\(majorVersion).\(minorVersion)"
    }

    var osVersionLong: String {
        "\(majorVersion).\(minorVersion).\(patchVersion)"
    }
}
