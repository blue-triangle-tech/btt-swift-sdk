//
//  Dictionary+RequestRepresentation.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import Foundation

extension Dictionary where Key == String, Value == String {
    enum RequestField: String {
        // Additional
        case browser
        case device
        case os
        // Session
        case isReturningVisitor = "RV"
        case wcd
        case eventType
        case navigationType
        case osInfo = "EUOS"
        case appVersion = "bvzn"
        case siteID
        case globalUserID = "gID"
        case sessionID = "sID"
        case abTestID = "AB"
        case campaignMedium = "CmpM"
        case campaignName = "CmpN"
        case campaignSource = "CmpS"
        case dataCenter = "DCTR"
        case trafficSegmentName = "txnName"
        // Page
        case brandValue = "bv"
        case pageName
        case pageType
        case referringURL = "RefURL"
        case url = "thisURL"
        // Timer
        case navigationStart = "nst"
        case unloadEventStart
        case domInteractive
        case pageTime = "pgTm"
        // PurchaseConfirmation
        case pageValue
        case cartValue
        case orderNumber = "ONumBr"
        case orderTime = "orderTND"
    }

    mutating func represent(_ value: String, forKey key: RequestField) {
        self[key.rawValue] = "\"\(value)\""
    }

    mutating func represent<T: Numeric>(_ value: T, forKey key: RequestField) {
        self[key.rawValue] = "\(value)"
    }

    mutating func represent(_ value: TimeInterval, forKey key: RequestField) {
        self[key.rawValue] = "\(Int((value * 1000).rounded()))"
    }
}
