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
    @Published var checkoutItem: Checkout?
    @Published var productItems: IdentifiedArrayOf<CartItemModel> = []
    @Published var error: Error?

    var estimatedTax: Double {
        Constants.averageSalesTax * subtotal
    }

    var subtotal: Double {
        productItems.reduce(into: 0) { result, item in
            result += item.price
        }
    }

    init(service: Service, cartRepository: CartRepository) {
        self.service = service
        self.cartRepository = cartRepository

        cartRepository.items
            .assign(to: &$productItems)
    }

    @MainActor
    func checkout() {
        Task {
            do {
                checkoutItem = try await cartRepository.checkout()
            } catch {
                self.error = error
            }
        }
    }

    @MainActor
    func increment(id: CartItemModel.ID) {
        guard let currentQuantity = productItems[id: id]?.quantity else {
            return
        }

        cartRepository.updateQuantity(cartItemID: id, quantity: currentQuantity + 1)
    }

    @MainActor
    func decrement(id: CartItemModel.ID) {
        guard let currentQuantity = productItems[id: id]?.quantity else {
            return
        }

        if currentQuantity > 1 {
            cartRepository.updateQuantity(cartItemID: id, quantity: currentQuantity - 1)
        } else {
            cartRepository.remove(cartItemID: id)
        }
    }
}

extension CartViewModel {
    func checkoutViewModel(_ checkout: Checkout) -> CheckoutViewModel {
        CheckoutViewModel(
            cartRepository: cartRepository,
            checkout: checkout,
            onFinish: { [weak self] in
                self?.checkoutItem = nil
            })
    }
}
