//
//  CartDetail.swift
//
//  Created by Mathew Gacy on 10/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CartDetail: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let confirmation: String
    public let shipping: String
    public let created: Date
    public let updated: Date
    public let items: [CartItem]

    public init(
        id: Int,
        confirmation: String,
        shipping: String,
        created: Date,
        updated: Date,
        items: [CartItem]
    ) {
        self.id = id
        self.confirmation = confirmation
        self.shipping = shipping
        self.created = created
        self.updated = updated
        self.items = items
    }
}
