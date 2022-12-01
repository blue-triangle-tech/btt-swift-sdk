//
//  CartRepository.swift
//
//  Created by Mathew Gacy on 11/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Combine
import Foundation
import IdentifiedCollections
import Service

final class CartRepository {
    private let service: Service
    private var cartDetail: CartDetail?
    let items = CurrentValueSubject<IdentifiedArrayOf<CartItemModel>, Never>([])

    init(service: Service) {
        self.service = service
    }

    func add(product: Product, quantity: Int) async throws {
        if let item = try await addProduct(product, quantity: quantity) {
            var currentItems = items.value
            currentItems[id: item.id] = item
            items.value = currentItems
        }
    }

    func updateQuantity(cartItemID: CartItem.ID, quantity: Int) async throws {
        guard let cartID = cartDetail?.id, let currentItem = items.value[id: cartItemID] else {
            return
        }

        let updatedItem = try await updateItem(
            cartItemID: cartItemID,
            product: currentItem.product,
            quantity: quantity)

        self.cartDetail = try await service.cart(id: cartID)

        items.value[id: cartItemID] = updatedItem
    }

    func remove(cartItemID: CartItem.ID) async throws {
        guard let cartID = cartDetail?.id else {
            return
        }

        try await service.deleteCartItem(id: cartItemID)
        items.value[id: cartItemID] = nil
        cartDetail = try await service.cart(id: cartID)
    }

    func checkout() async throws -> Checkout {
        guard let cartDetail else {
            throw "Missing Cart"
        }
        return try await service.checkout(id: cartDetail.id)
    }

    func confirm(_ checkoutID: Checkout.ID) async throws -> CartDetail {
        try await service.deleteCheckout(id: checkoutID)
    }
}

private extension CartRepository {
    func makeCart() async throws -> Cart {
        try await service.createCart(
            CreateCart(
                confirmation: UUID().uuidString,
                shipping: Constants.shipping,
                itemIDs: []))
    }

    func addProduct(_ product: Product, quantity: Int = 1) async throws -> CartItemModel? {
        if let cartDetail {
            if let existingItem = cartDetail.items.first(where: { $0.productID == product.id }) {
                guard quantity != existingItem.quantity else {
                    return nil
                }

                let productItem = try await updateItem(cartItemID: existingItem.id, product: product, quantity: quantity)
                self.cartDetail = try await service.cart(id: cartDetail.id)
                return productItem

            } else {
                let productItem = try await addItem(product: product, quantity: quantity, cartID: cartDetail.id)
                self.cartDetail = try await service.cart(id: cartDetail.id)
                return productItem
            }
        } else {
            let newCart = try await service.createCart(
                CreateCart(
                    confirmation: UUID().uuidString,
                    shipping: Constants.shipping))

            let productItem = try await addItem(product: product, quantity: quantity, cartID: newCart.id)
            cartDetail = try await service.cart(id: newCart.id)
            return productItem
        }
    }

    func addItem(product: Product, quantity: Int, cartID: Cart.ID) async throws -> CartItemModel {
        let cartItem = try await service.createCartItem(
            CreateCartItem(
                productID: product.id,
                quantity: quantity,
                price: product.price,
                cartID: cartID))

        return CartItemModel(
            id: cartItem.id,
            quantity: cartItem.quantity,
            product: product)
    }

    func updateItem(cartItemID: CartItem.ID, product: Product, quantity: Int) async throws -> CartItemModel {
        let cartItem = try await service.updateCartItem(
            UpdateCartItem(
                id: cartItemID,
                quantity: quantity))

        return CartItemModel(
            id: cartItem.id,
            quantity: cartItem.quantity,
            product: product)
    }
}

extension CartRepository {
    static var mock: CartRepository {
        .init(service: .mock)
    }
}
