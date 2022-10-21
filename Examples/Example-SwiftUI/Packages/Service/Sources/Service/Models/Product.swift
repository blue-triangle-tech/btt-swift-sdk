//
//  Product.swift
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct Product: Codable, Equatable, Hashable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String
    public let image: URL
    public let price: String

    public init(
        id: Int,
        name: String,
        description: String,
        image: URL,
        price: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.image = image
        self.price = price
    }
}
