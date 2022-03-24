//
//  TimerRequest.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct TimerRequest: Encodable {
    let session: Session
    let page: Page
    let timer: PageTimeInterval
    let purchaseConfirmation: PurchaseConfirmation?
    let performanceReport: PerformanceReport?

    func encode(to enc: Encoder) throws {
        var con = enc.container(keyedBy: CodingKeys.self)

        // Additional
        try con.encode(Constants.browser, forKey: .browser)
        try con.encode(Constants.device, forKey: .device)
        try con.encode(Constants.os, forKey: .os)

        // Session
        try con.encode(session.isReturningVisitor.smallInt, forKey: .rv)
        try con.encode(session.wcd, forKey: .wcd)
        try con.encode(session.eventType, forKey: .eventType)
        try con.encode(session.navigationType, forKey: .navigationType)
        try con.encode(session.osInfo, forKey: .osInfo)
        try con.encode(session.appVersion, forKey: .appVersion)
        try con.encode(session.siteID, forKey: .siteID)
        try con.encode(session.globalUserID, forKey: .globalUserID)
        try con.encode(session.sessionID, forKey: .sessionID)
        try con.encode(session.abTestID, forKey: .abTestID)
        try con.encode(session.campaign, forKey: .campaign)
        try con.encode(session.campaignMedium, forKey: .campaignMedium)
        try con.encode(session.campaignName, forKey: .campaignName)
        try con.encode(session.campaignSource, forKey: .campaignSource)
        try con.encode(session.dataCenter, forKey: .dataCenter)
        try con.encode(session.trafficSegmentName, forKey: .trafficSegmentName)

        // Page
        try con.encode(page.brandValue, forKey: .brandValue)
        try con.encode(page.pageName, forKey: .pageName)
        try con.encode(page.pageType, forKey: .pageType)
        try con.encode(page.referringURL, forKey: .referringURL)
        try con.encode(page.url, forKey: .url)

        // PurchaseConfirmation
        if let purchaseConfirmation = purchaseConfirmation {
            try con.encode(purchaseConfirmation.pageValue , forKey: .pageValue)
            try con.encode(purchaseConfirmation.cartValue , forKey: .cartValue)
            try con.encode(purchaseConfirmation.orderNumber , forKey: .orderNumber)
            try con.encode(purchaseConfirmation.orderTime.milliseconds , forKey: .orderTime)
        }

        // Timer
        try con.encode(timer.startTime, forKey: .navigationStart)
        try con.encode(timer.unloadStartTime, forKey: .unloadEventStart)
        try con.encode(timer.interactiveTime, forKey: .domInteractive)
        try con.encode(timer.pageTime, forKey: .pageTime)

        // Custom Variables
        if let customVars = page.customVariables {
            try con.encode(customVars.cv1, forKey: .cv1)
            try con.encode(customVars.cv2, forKey: .cv2)
            try con.encode(customVars.cv3, forKey: .cv3)
            try con.encode(customVars.cv4, forKey: .cv4)
            try con.encode(customVars.cv5, forKey: .cv5)
            try con.encode(customVars.cv11, forKey: .cv11)
            try con.encode(customVars.cv12, forKey: .cv12)
            try con.encode(customVars.cv13, forKey: .cv13)
            try con.encode(customVars.cv14, forKey: .cv14)
            try con.encode(customVars.cv15, forKey: .cv15)
        }

        if let customCats = page.customCategories {
            try con.encode(customCats.cv6, forKey: .cv6)
            try con.encode(customCats.cv7, forKey: .cv7)
            try con.encode(customCats.cv8, forKey: .cv8)
            try con.encode(customCats.cv9, forKey: .cv9)
            try con.encode(customCats.cv10, forKey: .cv10)
        }

        if let customNums = page.customNumbers {
            try con.encode(customNums.cn1, forKey: .cn1)
            try con.encode(customNums.cn2, forKey: .cn2)
            try con.encode(customNums.cn3, forKey: .cn3)
            try con.encode(customNums.cn4, forKey: .cn4)
            try con.encode(customNums.cn5, forKey: .cn5)
            try con.encode(customNums.cn6, forKey: .cn6)
            try con.encode(customNums.cn7, forKey: .cn7)
            try con.encode(customNums.cn8, forKey: .cn8)
            try con.encode(customNums.cn9, forKey: .cn9)
            try con.encode(customNums.cn10, forKey: .cn10)
            try con.encode(customNums.cn11, forKey: .cn11)
            try con.encode(customNums.cn12, forKey: .cn12)
            try con.encode(customNums.cn13, forKey: .cn13)
            try con.encode(customNums.cn14, forKey: .cn14)
            try con.encode(customNums.cn15, forKey: .cn15)
            try con.encode(customNums.cn16, forKey: .cn16)
            try con.encode(customNums.cn17, forKey: .cn17)
            try con.encode(customNums.cn18, forKey: .cn18)
            try con.encode(customNums.cn19, forKey: .cn19)
            try con.encode(customNums.cn20, forKey: .cn20)
        }

        if let performanceReport = performanceReport {
            try con.encode(performanceReport.minCPU, forKey: .minCPU)
            try con.encode(performanceReport.maxCPU, forKey: .maxCPU)
            try con.encode(performanceReport.avgCPU, forKey: .avgCPU)
            try con.encode(performanceReport.minMemory, forKey: .minMemory)
            try con.encode(performanceReport.maxMemory, forKey: .maxMemory)
            try con.encode(performanceReport.avgMemory, forKey: .avgMemory)
        }
    }

    enum CodingKeys: String, CodingKey {
        // Additional
        case browser
        case device
        case os
        // Session
        case rv = "RV"
        case wcd
        case eventType
        case navigationType
        case osInfo = "EUOS"
        case appVersion = "bvzn"
        case siteID
        case globalUserID = "gID"
        case sessionID = "sID"
        case abTestID = "AB"
        case campaign
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
        // case timeOnPage = "top"
        case navigationStart = "nst"
        case unloadEventStart
        case domInteractive
        case pageTime = "pgTm"
        // PurchaseConfirmation
        case pageValue
        case cartValue
        case orderNumber = "ONumBr"
        case orderTime = "orderTND"
        // CustomVariables
        case cv1 = "CV1"
        case cv2 = "CV2"
        case cv3 = "CV3"
        case cv4 = "CV4"
        case cv5 = "CV5"
        case cv11 = "CV11"
        case cv12 = "CV12"
        case cv13 = "CV13"
        case cv14 = "CV14"
        case cv15 = "CV15"
        // CustomCategories
        case cv6 = "CV6"
        case cv7 = "CV7"
        case cv8 = "CV8"
        case cv9 = "CV9"
        case cv10 = "CV10"
        // CustomNumbers
        case cn1 = "CN1"
        case cn2 = "CN2"
        case cn3 = "CN3"
        case cn4 = "CN4"
        case cn5 = "CN5"
        case cn6 = "CN6"
        case cn7 = "CN7"
        case cn8 = "CN8"
        case cn9 = "CN9"
        case cn10 = "CN10"
        case cn11 = "CN11"
        case cn12 = "CN12"
        case cn13 = "CN13"
        case cn14 = "CN14"
        case cn15 = "CN15"
        case cn16 = "CN16"
        case cn17 = "CN17"
        case cn18 = "CN18"
        case cn19 = "CN19"
        case cn20 = "CN20"
        // Performance Monitoring
        case minCPU
        case maxCPU
        case avgCPU
        case minMemory
        case maxMemory
        case avgMemory
    }
}
