//
//  Cart.swift
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct Cart: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let confirmation: String
    public let shipping: String
    public let created: Date
    public let updated: Date
    public let cartItemSet: [Int]

    public init(
        id: Int,
        confirmation: String,
        shipping: String,
        created: Date,
        updated: Date,
        cartItemSet: [Int]
    ) {
        self.id = id
        self.confirmation = confirmation
        self.shipping = shipping
        self.created = created
        self.updated = updated
        self.cartItemSet = cartItemSet
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case confirmation
        case shipping
        case created
        case updated
        case cartItemSet = "cartitem_set"
    }
}
