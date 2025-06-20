//
//  BTTRemoteConfig.swift
//
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class BTTRemoteConfig: Codable, Equatable {
    var networkSampleRateSDK: Int?
    var enableRemoteConfigAck: Bool?
    var ignoreScreens : [String]?
    var enableAllTracking: Bool?
    var groupingEnabled: Bool?
    var groupingIdleTime: Double?
    
    init(networkSampleRateSDK: Int?,
         enableRemoteConfigAck : Bool?,
         enableAllTracking : Bool?,
         groupingEnabled : Bool?,
         groupingIdleTime : Double?,
         ignoreScreens : [String]?) {
        self.networkSampleRateSDK = networkSampleRateSDK
        self.enableRemoteConfigAck = enableRemoteConfigAck
        self.ignoreScreens = ignoreScreens
        self.enableAllTracking = enableAllTracking
        self.groupingEnabled = groupingEnabled
        self.groupingIdleTime = groupingIdleTime
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
        lhs.ignoreScreens == rhs.ignoreScreens &&
        lhs.enableAllTracking == rhs.enableAllTracking &&
        lhs.groupingEnabled == rhs.groupingEnabled &&
        lhs.groupingIdleTime == rhs.groupingIdleTime
    }
    
    internal static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100),
                             enableRemoteConfigAck : false, 
                             enableAllTracking: true,
                             groupingEnabled: BlueTriangle.configuration.groupingEnabled,
                             groupingIdleTime: BlueTriangle.configuration.groupingIdleTime,
                             ignoreScreens: Array(BlueTriangle.configuration.ignoreViewControllers),
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
