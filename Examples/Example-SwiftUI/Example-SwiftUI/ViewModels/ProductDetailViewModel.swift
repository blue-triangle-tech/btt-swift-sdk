//
//  ProductDetailViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class ProductDetailViewModel: ObservableObject {
    @Published var error: Error?
    @Published var quantity: Int
    private let cartRepository: CartRepository
    private let imageLoader: ImageLoader
    private let product: Product

    var name: String {
        product.name
    }

    var description: String {
        product.description
    }

    var price: String {
        "$\(product.price)"
    }

    init(
        cartRepository: CartRepository,
        imageLoader: ImageLoader,
        product: Product, quantity: Int = 1
    ) {
        self.cartRepository = cartRepository
        self.imageLoader = imageLoader
        self.product = product
        self.quantity = quantity
    }

    @MainActor
    func imageStatus() async -> ImageStatus? {
        // Start timer ...

        let status = await imageLoader.images[product.image]

        // End timer
        print("End \(String(describing: self)) Timer")

        return status
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
