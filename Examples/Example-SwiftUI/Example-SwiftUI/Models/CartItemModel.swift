//
//  CartItemModel.swift
//
//  Created by Mathew Gacy on 11/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

struct CartItemModel: Codable, Equatable, Hashable, Identifiable {
    var id: Int
    var quantity: Int
    var product: Product

    var price: Double {
        Double(product.price).flatMap { $0 * Double(quantity) } ?? 0
    }
}
