//
//  ChckoutItem.swift
//
//  Created by Mathew Gacy on 10/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct CheckoutItem: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let product: Int
    public let quantity: Int
    public let price: String

    public init(
        id: Int,
        product: Int,
        quantity: Int,
        price: String
    ) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.price = price
    }
}
