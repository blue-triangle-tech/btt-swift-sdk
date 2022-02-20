//
//  Page.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

// TODO: use more appropriate name for mobile context
@objcMembers
final public class Page: NSObject {

    /// Brand Value, Optional static monetary amount assigned to a step in the user’s path
    /// signing up for a credit card is a zero dollar transaction, but has business value.
    public var brandValue: Decimal

    /// Name of page.
    public var pageName: String

    /// Page or content grouping designation.
    public var pageType: String

    /// Referring URL.
    public var referringURL: String

    /// Description
    public var url: String

    public var customVariables: CustomVariables?

    public var customCategories: CustomCategories?

    public var customNumbers: CustomNumbers?

    public init(
        pageName: String,
        brandValue: Decimal = 0.0,
        pageType: String = "Main Group",
        referringURL: String = "",
        url: String = "",
        customVariables: CustomVariables? = nil,
        customCategories: CustomCategories? = nil,
        customNumbers: CustomNumbers? = nil
    ) {
        self.brandValue = brandValue
        self.pageName = pageName
        self.pageType = pageType
        self.referringURL = referringURL
        self.url = url
        self.customVariables = customVariables
        self.customCategories = customCategories
        self.customNumbers = customNumbers
    }
}

// MARK: - Crash Reporting
extension Page {
    convenience init(deviceName: String = "Unknown%20iOS%20Device") {
        self.init(pageName: "iOSCrash\(deviceName)", pageType: "")
    }
}
