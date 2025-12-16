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

public final class Device: @unchecked Sendable {
    public static let current = Device()
    private init() {}
    
    public private(set) var os: String = ""
    public private(set) var osVersion: String = ""
    public private(set) var name: String = ""
    public private(set) var bvzn: String = ""
    public private(set) var appVersion: String = ""
    public private(set) var sdkVersion: String = ""
    public private(set) var userAgentToken: String = ""
    public private(set) var model: String = ""
    
    @MainActor
    internal func loadDeviceInfo() {
         initDeviceInfo()
    }
}

extension Device {
    
    @MainActor
    private func initDeviceInfo()  {
        let basic = Self.makeBasicInfo()
        let versions = Self.makeVersionInfo(
            os: basic.os,
            osVersion: basic.osVersion,
            model: basic.model
        )
        
        self.os = basic.os
        self.osVersion = basic.osVersion
        self.name = basic.name
        self.model = basic.model
        self.appVersion = versions.appVersion
        self.sdkVersion = versions.sdkVersion
        self.bvzn = versions.bvzn
        self.userAgentToken = versions.userAgentToken
    }
    
    /// Collects OS, version, name, and model
    @MainActor
    private static func makeBasicInfo() -> (
        os: String,
        osVersion: String,
        name: String,
        model: String
    ) {
        let os: String
        let osVersion: String
        let name: String
        let model: String

        #if os(iOS) || os(tvOS)
        let device = UIDevice.current
        os = device.systemName
        osVersion = device.systemVersion
        name = device.name
        model = deviceModel()

        #elseif os(watchOS)
        let d = WKInterfaceDevice.current()
        os = d.systemName
        osVersion = d.systemVersion
        name = d.model
        model = deviceModel()

        #elseif os(macOS)
        os = "macOS"
        osVersion = ProcessInfo.processInfo.operatingSystemVersion.osVersionShort
        name = platform()
        model = platform()

        #else
        os = "UNKNOWN OS"
        osVersion = ""
        name = "UNKNOWN DEVICE"
        model = ""
        #endif

        return (os, osVersion, name, model)
    }

    
    /// Build version strings, browser version, user-agent, etc.
    private static func makeVersionInfo(
        os: String,
        osVersion: String,
        model: String
    ) -> (
        appVersion: String,
        sdkVersion: String,
        bvzn: String,
        userAgentToken: String
    ) {
        let appVersion = Bundle.main.releaseVersionNumber ?? "0.0"
        let sdkVersion = Version.number
        let bvzn = "\(Constants.browser)-\(appVersion)-\(os) \(osVersion)"
        let userAgent = "\(os)/\(osVersion) (\(model))"

        return (appVersion, sdkVersion, bvzn, userAgent)
    }
}

extension Device {
    private static func deviceModel() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private static func platform() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
