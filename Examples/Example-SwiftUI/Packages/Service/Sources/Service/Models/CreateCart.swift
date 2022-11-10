//
//  CreateCart.swift
//
//  Created by Mathew Gacy on 10/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CreateCart: Codable, Equatable {
    public let confirmation: String
    public let shipping: String
    public let itemIDs: Set<Int>

    public init(
        confirmation: String,
        shipping: String,
        itemIDs: Set<Int> = []
    ) {
        self.confirmation = confirmation
        self.shipping = shipping
        self.itemIDs = itemIDs
    }

    private enum CodingKeys: String, CodingKey {
        case confirmation
        case shipping
        case itemIDs = "cartitem_set"
    }
}
