//
//  Device.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import class UIKit.UIDevice
#elseif os(watchOS)
import WatchKit
#endif

enum Device {

    static var bvzn: String {
        "\(Constants.browser)-\(Bundle.main.releaseVersionNumber ?? "0.0")-\(os) \(osVersion)"
    }

    static var os: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.systemName
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemName
        #elseif os(macOS)
        return "macOS"
        #else
        return "UNKNOWN OS"
        #endif
    }

    static var osVersion: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.systemVersion
        #elseif os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(macOS)
        return ProcessInfo.processInfo.operatingSystemVersion.osVersionShort
        #else
        return ""
        #endif
    }

    static var name: String {
        #if os(iOS) || os(tvOS)
        return UIDevice.current.name
        #elseif os(watchOS)
        return WKInterfaceDevice.current().model
        #elseif os(macOS)
        return platform()
        #endif
    }

    private static func platform() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
