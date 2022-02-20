//
//  CustomCategories.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

@objcMembers
final public class CustomCategories: NSObject {
    public var cv6: String?
    public var cv7: String?
    public var cv8: String?
    public var cv9: String?
    public var cv10: String?

    public init(
        cv6: String?,
        cv7: String?,
        cv8: String?,
        cv9: String?,
        cv10: String?
    ) {
        self.cv6 = cv6
        self.cv7 = cv7
        self.cv8 = cv8
        self.cv9 = cv9
        self.cv10 = cv10
    }
}
