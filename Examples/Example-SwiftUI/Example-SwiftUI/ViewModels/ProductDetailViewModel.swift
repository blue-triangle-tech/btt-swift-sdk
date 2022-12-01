//
//  ProductDetailViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class ProductDetailViewModel: ObservableObject {
    private let cartRepository: CartRepository
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

    init(cartRepository: CartRepository, product: Product, quantity: Int = 1) {
        self.cartRepository = cartRepository
        self.product = product
        self.quantity = quantity
    }

    @MainActor
    func addToCart() async {
        do {
            try  await cartRepository.add(
                product: product,
                quantity: quantity)
        } catch {
            self.error = error
        }
    }
}
