//
//  NativeAppProperties.swift
//  
//
//  Created by JP on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

enum ScreenType : String, Encodable, Decodable, Sendable {
    case UIKit
    case SwiftUI
    case Manual
}

enum NativeAppType : CustomStringConvertible, Encodable, Decodable{
    case Regular
    case NST
    
    internal var description: String {
        switch self {
        case .Regular:
            return "regular"
        case .NST:
            return "nst"
        }
    }
}

struct NativeAppProperties: Equatable , Sendable{
    let fullTime: Millisecond
    let loadTime: Millisecond
    let loadStartTime: Millisecond
    let loadEndTime: Millisecond
    let maxMainThreadUsage: Millisecond
    let numberOfCPUCores: Int32 = Int32(ProcessInfo.processInfo.activeProcessorCount)
    let screenType: ScreenType?
    let offline: Millisecond
    let wifi: Millisecond
    let cellular: Millisecond
    let ethernet: Millisecond
    let other: Millisecond
    var confidenceRate: Int32?
    var confidenceMsg: String?
    var grouped: Bool?
    var err: String?
    var groupingCause: String?
    var groupingCauseInterval: Millisecond?
    var sdkVersion: String = Device.current.sdkVersion
    var appVersion: String = Device.current.appVersion
    var type : String = NativeAppType.Regular.description
    var netState: String = ""
    var deviceModel : String = Device.current.model
    var netStateSource : String = ""
    var childViews:[String] = [String]()
}

extension NativeAppProperties {
    static func make(
        fullTime: Millisecond,
        loadTime: Millisecond,
        loadStartTime: Millisecond,
        loadEndTime: Millisecond,
        maxMainThreadUsage: Millisecond,
        screenType: ScreenType?,
        offline: Millisecond,
        wifi: Millisecond,
        cellular: Millisecond,
        ethernet: Millisecond,
        other: Millisecond,
        type: String = NativeAppType.Regular.description,
        confidenceRate: Int32? = nil,
        confidenceMsg: String? = nil,
        grouped: Bool? = nil,
        err: String? = nil,
        groupingCause: String? = nil,
        groupingCauseInterval: Millisecond? = nil,
        childViews: [String] = []
    ) async -> NativeAppProperties {
        let netState = await BlueTriangle.networkStateMonitor()?.state.value?.description.lowercased() ?? ""
        let netStateSource = await BlueTriangle.networkStateMonitor()?.networkSource.value?.description ?? ""

        return NativeAppProperties(
            fullTime: fullTime,
            loadTime: loadTime,
            loadStartTime: loadStartTime,
            loadEndTime: loadEndTime,
            maxMainThreadUsage: maxMainThreadUsage,
            screenType: screenType,
            offline: offline,
            wifi: wifi,
            cellular: cellular,
            ethernet: ethernet,
            other: other,
            confidenceRate: confidenceRate,
            confidenceMsg: confidenceMsg,
            grouped: grouped,
            err: err,
            groupingCause: groupingCause,
            groupingCauseInterval: groupingCauseInterval,
            sdkVersion: Device.current.sdkVersion,
            appVersion: Device.current.appVersion,
            type: NativeAppType.Regular.description,
            netState: netState,
            deviceModel: Device.current.model,
            netStateSource: netStateSource,
            childViews: childViews
        )
    }
}

extension NativeAppProperties: Codable{
    
    func encode(to encoder: Encoder) throws {
        var con = encoder.container(keyedBy: CodingKeys.self)
       
        if fullTime > 0{
            try con.encode(fullTime, forKey: .fullTime)
        }
        
        if loadTime > 0{
            try con.encode(loadTime, forKey: .loadTime)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(maxMainThreadUsage, forKey: .maxMainThreadUsage)
        }
        
        if self.type != NativeAppType.NST.description{
            try con.encode(numberOfCPUCores, forKey: .numberOfCPUCores)
        }
                
        if screenType != nil{
            try con.encode(screenType, forKey: .screenType)
        }
        
        if offline > 0{
            try con.encode(offline, forKey: .offline)
        }
        if wifi > 0{
            try con.encode(wifi, forKey: .wifi)
        }
        if cellular > 0{
            try con.encode(cellular, forKey: .cellular)
        }
        if ethernet > 0{
            try con.encode(ethernet, forKey: .ethernet)
        }
        if other > 0{
            try con.encode(other, forKey: .other)
        }
        
        if let err = err, err.count > 0{
            try con.encode(err, forKey: .err)
        }
    
        if netState.count > 0{
            try con.encode(netState, forKey: .netState)
        }
        
        if netStateSource.count > 0{
            try con.encode(netStateSource, forKey: .netStateSource)
        }
        
        if childViews.count > 0{
            try con.encode(childViews, forKey: .childViews)
        }
        
        if let confidenceRate = confidenceRate {
            try con.encode(confidenceRate, forKey: .confidenceRate)
        }
        
        if let confidenceMsg = confidenceMsg {
            try con.encode(confidenceMsg, forKey: .confidenceMsg)
        }
        
        if let grouped = grouped {
            try con.encode(grouped, forKey: .grouped)
        }
        
        if let cause = groupingCause {
            try con.encode(cause, forKey: .groupingCause)
        }
        
        if let interval  = groupingCauseInterval {
            try con.encode(interval, forKey: .groupingCauseInterval)
        }
        
        try con.encode(deviceModel, forKey: .deviceModel)
        try con.encode(appVersion, forKey: .appVersion)
        try con.encode(sdkVersion, forKey: .sdkVersion)
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.fullTime = try container.decodeIfPresent(Millisecond.self, forKey: .fullTime)  ?? 0
        self.loadTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadTime)  ?? 0
        self.loadStartTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadStartTime)  ?? 0
        self.loadEndTime = try container.decodeIfPresent(Millisecond.self, forKey: .loadEndTime)  ?? 0
        self.maxMainThreadUsage = try container.decodeIfPresent(Millisecond.self, forKey: .maxMainThreadUsage)  ?? 0
        self.screenType = try container.decodeIfPresent(ScreenType.self, forKey: .screenType)
        self.wifi = try container.decodeIfPresent(Millisecond.self, forKey: .wifi)  ?? 0
        self.offline = try container.decodeIfPresent(Millisecond.self, forKey: .offline)  ?? 0
        self.cellular = try container.decodeIfPresent(Millisecond.self, forKey: .cellular)  ?? 0
        self.ethernet = try container.decodeIfPresent(Millisecond.self, forKey: .ethernet)  ?? 0
        self.other = try container.decodeIfPresent(Millisecond.self, forKey: .other) ?? 0
        self.netState = try container.decodeIfPresent(String.self, forKey: .netState) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? NativeAppType.NST.description
        self.deviceModel = try container.decodeIfPresent(String.self, forKey: .deviceModel) ?? Device.current.model
        self.appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? Device.current.appVersion
        self.sdkVersion = try container.decodeIfPresent(String.self, forKey: .sdkVersion) ?? Device.current.sdkVersion
        self.netStateSource = try container.decodeIfPresent(String.self, forKey: .netStateSource) ?? ""
        self.childViews = try container.decodeIfPresent([String].self, forKey: .childViews) ?? []
        self.confidenceRate = try container.decodeIfPresent(Int32.self, forKey: .confidenceRate) ?? 0
        self.confidenceMsg = try container.decodeIfPresent(String.self, forKey: .confidenceMsg) ?? ""
        self.groupingCause = try container.decodeIfPresent(String.self, forKey: .groupingCause) ?? ""
        self.groupingCauseInterval = try container.decodeIfPresent(Millisecond.self, forKey: .groupingCauseInterval) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case fullTime
        case loadTime
        case loadStartTime
        case loadEndTime
        case maxMainThreadUsage
        case numberOfCPUCores
        case screenType
        case offline
        case wifi
        case cellular
        case ethernet
        case netState
        case other
        case type
        case err
        case deviceModel
        case netStateSource
        case childViews
        case appVersion
        case grouped
        case sdkVersion
        case confidenceRate
        case confidenceMsg
        case groupingCause
        case groupingCauseInterval
    }
}

extension NativeAppProperties {
    
    static func `init`(_ error : String?) async -> Self{
        return await make(
            fullTime: 0,
            loadTime: 0,
            loadStartTime: 0,
            loadEndTime: 0,
            maxMainThreadUsage: 0,
            screenType: nil,
            offline: 0,
            wifi: 0,
            cellular: 0,
            ethernet: 0,
            other: 0,
            type: NativeAppType.NST.description,
            err: error
        )
    }
    
    static let empty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        loadStartTime: 0,
        loadEndTime: 0,
        maxMainThreadUsage: 0,
        screenType: nil,
        offline: 0,
        wifi: 0,
        cellular: 0,
        ethernet: 0,
        other: 0)
    
    static var nstEmpty: Self {
        get async {
            await NativeAppProperties.make(
                fullTime: 0,
                loadTime: 0,
                loadStartTime: 0,
                loadEndTime: 0,
                maxMainThreadUsage: 0,
                screenType: nil,
                offline: 0,
                wifi: 0,
                cellular: 0,
                ethernet: 0,
                other: 0,
                type: NativeAppType.NST.description
            )
        }
    }
    
    func copy(_ type: NativeAppType) async -> NativeAppProperties {
        return await NativeAppProperties.make(
            fullTime: self.fullTime,
            loadTime: self.loadTime,
            loadStartTime: self.loadStartTime,
            loadEndTime: self.loadEndTime,
            maxMainThreadUsage: self.maxMainThreadUsage,
            screenType: self.screenType,
            offline: self.offline,
            wifi: self.wifi,
            cellular: self.cellular,
            ethernet: self.ethernet,
            other: self.other,
            type: type.description
        )
    }
}
