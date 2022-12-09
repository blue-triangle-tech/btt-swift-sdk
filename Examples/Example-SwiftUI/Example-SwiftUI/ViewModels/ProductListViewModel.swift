//
//  ProductListViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class ProductListViewModel: ObservableObject {
    @Published private(set) var products: ([Product], [Product]) = ([], [])
    @Published var error: Error?
    private let cartRepository: CartRepository
    private let service: Service

    init(cartRepository: CartRepository, service: Service) {
        self.cartRepository = cartRepository
        self.service = service
    }

    @MainActor
    func loadProducts() async {
        do {
            products = try await service.products().splitTuple()
        } catch {
            self.error = error
        }
    }

    func detailViewModel(for productID: Product.ID) -> ProductDetailViewModel? {
        guard let product = products.0.first(where: { $0.id == productID }) ?? products.1.first(where: { $0.id == productID }) else  {
            return nil
        }

        return ProductDetailViewModel(
            cartRepository: cartRepository,
            product: product)
    }
}
