//
//  ProductDetailViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
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
        // Start timer
        let timer = BlueTriangle.startTimer(
            page: Page(
                pageName: "ProductDetail: \(product.name)"))

        let status = await imageLoader.images[product.image]

        // End timer
        BlueTriangle.endTimer(timer)

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
