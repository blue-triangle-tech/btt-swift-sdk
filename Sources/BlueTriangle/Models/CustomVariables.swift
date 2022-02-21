//
//  CustomVariables.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// Custom textual data that is related to individual views but does not need to be seen
/// at a larger, aggregate scale. This is similar to `CustomCategories` but they're not
/// aggregated and do not appear as filter options.
@objcMembers
final public class CustomVariables: NSObject {
    public var cv1: String?
    public var cv2: String?
    public var cv3: String?
    public var cv4: String?
    public var cv5: String?
    public var cv11: String?
    public var cv12: String?
    public var cv13: String?
    public var cv14: String?
    public var cv15: String?

    public init(
        cv1: String?,
        cv2: String?,
        cv3: String?,
        cv4: String?,
        cv5: String?,
        cv11: String?,
        cv12: String?,
        cv13: String?,
        cv14: String?,
        cv15: String?
    ) {
        self.cv1 = cv1
        self.cv2 = cv2
        self.cv3 = cv3
        self.cv4 = cv4
        self.cv5 = cv5
        self.cv11 = cv11
        self.cv12 = cv12
        self.cv13 = cv13
        self.cv14 = cv14
        self.cv15 = cv15
    }
}
