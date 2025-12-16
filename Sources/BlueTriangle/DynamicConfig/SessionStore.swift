//
//  SessionStore.swift
//  
//
//  Created by Ashok Singh on 07/11/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

class SessionStore {
    
    private let sessionKey = "SAVED_SESSION_DATA"
    
    func saveSession(_ session: SessionData) {
        if let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: sessionKey)
        }
    }
    
    func retrieveSessionData() -> SessionData? {
        if let savedSession = UserDefaults.standard.object(forKey: sessionKey) as? Data {
            if let decodedSession = try? JSONDecoder().decode(SessionData.self, from: savedSession) {
                return decodedSession
            }
        }
        
        return nil
    }
    
    func isExpired() -> Bool{
        
        var isExpired : Bool = true
        
        if let session = retrieveSessionData(){
            let currentTime = Int64(Date().timeIntervalSince1970) * 1000
            if  currentTime > session.expiration{
                isExpired = true
            }else{
                isExpired = false
            }
        }else{
            isExpired = true
        }
        
        return isExpired
    }
    
    func removeSessionData() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        UserDefaults.standard.synchronize()
    }
}

final class SessionData: Codable, @unchecked Sendable {

    private let lock = NSLock()
    private var _expiration: Millisecond
    private var _isNewSession: Bool
    private var _shouldNetworkCapture: Bool
    private var _shouldGroupedViewCapture: Bool
    private var _enableScreenTracking: Bool
    private var _networkSampleRate: Double
    private var _groupedViewSampleRate: Double
    private var _enableGrouping: Bool
    private var _groupingIdleTime: Double
    private var _ignoreViewControllers: Set<String>
    
    let sessionID: Identifier

    init(expiration: Millisecond) {
        self.sessionID = SessionData.generateSessionID()
        self._expiration = expiration
        self._isNewSession = true
        self._shouldNetworkCapture = false
        self._shouldGroupedViewCapture = false
        self._groupedViewSampleRate = BlueTriangle.configuration.groupedViewSampleRate
        self._enableGrouping = BlueTriangle.configuration.enableGrouping
        self._groupingIdleTime = BlueTriangle.configuration.groupingIdleTime
        self._enableScreenTracking = BlueTriangle.configuration.enableScreenTracking
        self._networkSampleRate = BlueTriangle.configuration.networkSampleRate
        self._ignoreViewControllers = BlueTriangle.configuration.ignoreViewControllers
    }

    private static func generateSessionID() -> Identifier {
        return Identifier.random()
    }

    var expiration: Millisecond {
        get { lock.sync { _expiration } }
        set { lock.sync { _expiration = newValue } }
    }
    
    var isNewSession: Bool {
        get { lock.sync { _isNewSession } }
        set { lock.sync { _isNewSession = newValue } }
    }
    
    var shouldNetworkCapture: Bool {
        get { lock.sync { _shouldNetworkCapture } }
        set { lock.sync { _shouldNetworkCapture = newValue } }
    }
    
    var shouldGroupedViewCapture: Bool {
        get { lock.sync { _shouldGroupedViewCapture } }
        set { lock.sync { _shouldGroupedViewCapture = newValue } }
    }
    
    var enableScreenTracking: Bool {
        get { lock.sync { _enableScreenTracking } }
        set { lock.sync { _enableScreenTracking = newValue } }
    }
    
    var networkSampleRate: Double {
        get { lock.sync { _networkSampleRate } }
        set { lock.sync { _networkSampleRate = newValue } }
    }
    
    var groupedViewSampleRate: Double {
        get { lock.sync { _groupedViewSampleRate } }
        set { lock.sync { _groupedViewSampleRate = newValue } }
    }
    
    var enableGrouping: Bool {
        get { lock.sync { _enableGrouping } }
        set { lock.sync { _enableGrouping = newValue } }
    }
    
    var groupingIdleTime: Double {
        get { lock.sync { _groupingIdleTime } }
        set { lock.sync { _groupingIdleTime = newValue } }
    }
    
    var ignoreViewControllers: Set<String> {
        get { lock.sync { _ignoreViewControllers } }
        set { lock.sync { _ignoreViewControllers = newValue } }
    }

    enum CodingKeys: String, CodingKey {
        case sessionID, expiration, isNewSession, shouldNetworkCapture,
             shouldGroupedViewCapture, enableScreenTracking, networkSampleRate,
             groupedViewSampleRate, enableGrouping, groupingIdleTime, ignoreViewControllers
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionID = try container.decode(Identifier.self, forKey: .sessionID)
        self._expiration = try container.decode(Millisecond.self, forKey: .expiration)
        self._isNewSession = try container.decode(Bool.self, forKey: .isNewSession)
        self._shouldNetworkCapture = try container.decode(Bool.self, forKey: .shouldNetworkCapture)
        self._shouldGroupedViewCapture = try container.decode(Bool.self, forKey: .shouldGroupedViewCapture)
        self._enableScreenTracking = try container.decode(Bool.self, forKey: .enableScreenTracking)
        self._networkSampleRate = try container.decode(Double.self, forKey: .networkSampleRate)
        self._groupedViewSampleRate = try container.decode(Double.self, forKey: .groupedViewSampleRate)
        self._enableGrouping = try container.decode(Bool.self, forKey: .enableGrouping)
        self._groupingIdleTime = try container.decode(Double.self, forKey: .groupingIdleTime)
        self._ignoreViewControllers = try container.decode(Set<String>.self, forKey: .ignoreViewControllers)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(expiration, forKey: .expiration)
        try container.encode(isNewSession, forKey: .isNewSession)
        try container.encode(shouldNetworkCapture, forKey: .shouldNetworkCapture)
        try container.encode(shouldGroupedViewCapture, forKey: .shouldGroupedViewCapture)
        try container.encode(enableScreenTracking, forKey: .enableScreenTracking)
        try container.encode(networkSampleRate, forKey: .networkSampleRate)
        try container.encode(groupedViewSampleRate, forKey: .groupedViewSampleRate)
        try container.encode(enableGrouping, forKey: .enableGrouping)
        try container.encode(groupingIdleTime, forKey: .groupingIdleTime)
        try container.encode(ignoreViewControllers, forKey: .ignoreViewControllers)
    }
}
