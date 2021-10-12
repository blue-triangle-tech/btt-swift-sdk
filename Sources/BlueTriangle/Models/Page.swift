//
//  Page.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final public class Page: NSObject {

    /// Brand Value, Optional static monetary amount assigned to a step in the user’s path
    /// signing up for a credit card is a zero dollar transaction, but has business value.
    @objc public var brandValue: Decimal // `bv`

    /// Name of page.
    @objc public var pageName: String // `pageName`

    /// Page or content grouping designation.
    @objc public var pageType: String // `pageType`

    /// Referring URL.
    @objc public var referringURL: String // `RefURL`

    /// Description
    @objc public var url: String

    @objc public var customVariables: CustomVariables?

    @objc public var customCategories: CustomCategories?

    @objc public var customNumbers: CustomNumbers?

    @objc public init(
        brandValue: Decimal,
        pageName: String,
        pageType: String,
        referringURL: String,
        url: String,
        customVariables: CustomVariables?,
        customCategories: CustomCategories?,
        customNumbers: CustomNumbers?
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
