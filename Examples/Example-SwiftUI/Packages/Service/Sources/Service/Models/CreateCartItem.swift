//
//  CreateCartItem.swift
//
//  Created by Mathew Gacy on 10/31/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CreateCartItem: Codable, Equatable, Hashable {
    public let productID: Int
    public let quantity: Int
    public let price: String
    public let cartID: Int

    public init(
        productID: Int,
        quantity: Int,
        price: String,
        cartID: Int
    ) {
        self.productID = productID
        self.quantity = quantity
        self.price = price
        self.cartID = cartID
    }

    private enum CodingKeys: String, CodingKey {
        case productID = "product"
        case quantity
        case price
        case cartID = "cart"
    }
}
