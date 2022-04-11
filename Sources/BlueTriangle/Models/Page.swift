//
//  Page.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object describing a user interaction.
@objcMembers
final public class Page: NSObject {
    /// A static monetary amount assigned to a step in the user’s path. Signing up for a
    /// credit card, for example, is a zero-dollar transaction that nevertheless has
    /// business value.
    public var brandValue: Decimal

    /// Name of page.
    public var pageName: String

    /// Page or content grouping designation.
    public var pageType: String

    /// Referring URL.
    public var referringURL: String

    /// URL.
    public var url: String

    /// Custom textual data that is relevant to individual views but is not aggregated.
    public var customVariables: CustomVariables?

    /// Custom textual data that is aggregated and appears in the list of filter options
    /// in the Blue Triangle portal.
    public var customCategories: CustomCategories?

    /// Custom numeric data that is aggregated and will appear on your trend graphs in
    /// the Blue Triangle portal.
    public var customNumbers: CustomNumbers?

    /// Creates a page describing a user interaction.
    /// - Parameters:
    ///   - pageName: Name of the page.
    ///   - brandValue: A monetary amount assigned to a step in the user's path.
    ///   - pageType: Page or content grouping designation.
    ///   - referringURL: Referring URL.
    ///   - url: URL.
    ///   - customVariables: Custom textual data that is relevant to individual views.
    ///   - customCategories: Custom textual data that is relevant to aggregate views.
    ///   - customNumbers: Custom numeric data that is relevant to aggregate views.
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
