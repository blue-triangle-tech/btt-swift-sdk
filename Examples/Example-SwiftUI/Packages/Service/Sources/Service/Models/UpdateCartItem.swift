//
//  UpdateCartItem.swift
//
//  Created by Mathew Gacy on 11/2/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct UpdateCartItem: Encodable, Equatable, Hashable {
    public let id: Int
    public let productID: Int?
    public let quantity: Int?
    public let price: String?
    public let cartID: Int?

    public init(
        id: Int,
        productID: Int? = nil,
        quantity: Int? = nil,
        price: String? = nil,
        cartID: Int? = nil
    ) {
        self.id = id
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
