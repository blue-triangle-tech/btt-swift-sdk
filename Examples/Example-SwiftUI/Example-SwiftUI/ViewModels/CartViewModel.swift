//
//  CartViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import IdentifiedCollections
import Service

final class CartViewModel: ObservableObject {
    private let service: Service
    private let cartRepository: CartRepository
    @Published var productItems: IdentifiedArrayOf<CartProductItem> = []
    @Published var error: Error?

    init(service: Service, cartRepository: CartRepository) {
        self.service = service
        self.cartRepository = cartRepository

        cartRepository.items
            .assign(to: &$productItems)
    }
}
