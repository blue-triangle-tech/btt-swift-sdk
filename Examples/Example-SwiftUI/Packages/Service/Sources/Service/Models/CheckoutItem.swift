//
//  ChckoutItem.swift
//
//  Created by Mathew Gacy on 10/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CheckoutItem: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let productID: Int
    public let quantity: Int
    public let price: String

    public init(
        id: Int,
        productID: Int,
        quantity: Int,
        price: String
    ) {
        self.id = id
        self.productID = productID
        self.quantity = quantity
        self.price = price
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case productID = "product"
        case quantity
        case price
    }
}
