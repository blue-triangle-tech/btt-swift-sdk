//
//  ProductDetailViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class ProductDetailViewModel: ObservableObject {
    private let product: Product
    @Published var quantity: Int
    @Published var error: Error?

    var name: String {
        product.name
    }

    var description: String {
        product.description
    }

    var price: String {
        "$\(product.price)"
    }

    var imageURL: URL {
        product.image
    }

    init(product: Product, quantity: Int = 1) {
        self.product = product
        self.quantity = quantity
    }

    func addToCart() {
    }
}
