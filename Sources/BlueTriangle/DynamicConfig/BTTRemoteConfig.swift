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
    var groupedViewSampleRate: Int?
    var enableRemoteConfigAck: Bool?
    var ignoreScreens : [String]?
    var enableAllTracking: Bool?
    var enableScreenTracking : Bool?
    var enableGrouping: Bool?
    var groupingIdleTime: Double?
    
    init(networkSampleRateSDK: Int?,
         groupedViewSampleRate: Int?,
         enableRemoteConfigAck : Bool?,
         enableAllTracking : Bool?,
         enableScreenTracking: Bool?,
         enableGrouping : Bool?,
         groupingIdleTime : Double?,
         ignoreScreens : [String]?) {
             self.networkSampleRateSDK = networkSampleRateSDK
             self.groupedViewSampleRate = groupedViewSampleRate
             self.enableRemoteConfigAck = enableRemoteConfigAck
             self.ignoreScreens = ignoreScreens
             self.enableAllTracking = enableAllTracking
             self.enableScreenTracking = enableScreenTracking
             self.enableGrouping = enableGrouping
             self.groupingIdleTime = groupingIdleTime
    }
    
    static func == (lhs: BTTRemoteConfig, rhs: BTTRemoteConfig) -> Bool {
        return lhs.networkSampleRateSDK == rhs.networkSampleRateSDK &&
        lhs.enableRemoteConfigAck == rhs.enableRemoteConfigAck  &&
        lhs.groupedViewSampleRate == rhs.groupedViewSampleRate  &&
        lhs.ignoreScreens == rhs.ignoreScreens &&
        lhs.enableAllTracking == rhs.enableAllTracking &&
        lhs.enableScreenTracking == rhs.enableScreenTracking &&
        lhs.enableGrouping == rhs.enableGrouping &&
        lhs.groupingIdleTime == rhs.groupingIdleTime
    }
    
    internal static var defaultConfig: BTTSavedRemoteConfig {
        BTTSavedRemoteConfig(networkSampleRateSDK: Int(BlueTriangle.configuration.networkSampleRate * 100),
                             groupedViewSampleRate: Int(BlueTriangle.configuration.groupedViewSampleRate * 100),
                             enableRemoteConfigAck : false,
                             enableAllTracking: true,
                             enableScreenTracking: BlueTriangle.configuration.enableScreenTracking,
                             enableGrouping: BlueTriangle.configuration.enableGrouping,
                             groupingIdleTime: BlueTriangle.configuration.groupingIdleTime,
                             ignoreScreens: Array(BlueTriangle.configuration.ignoreViewControllers),
                             dateSaved: Date().timeIntervalSince1970.milliseconds)
    }
}
