//
//  CartItem.swift
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CartItem: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let product: Int
    public let quantity: Int
    public let price: String
    public let cart: Int

    public init(
        id: Int,
        product: Int,
        quantity: Int,
        price: String,
        cart: Int
    ) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.price = price
        self.cart = cart
    }
}
