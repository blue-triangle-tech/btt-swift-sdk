//
//  CartModel.swift
//
//  Created by Mathew Gacy on 11/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import IdentifiedCollections
import Service

struct CartModel {
    var cart: Cart
    var items: IdentifiedArrayOf<CartItemModel>

    var subtotal: Double {
        items.reduce(into: 0) { result, element in
            result += element.price
        }
    }
}
