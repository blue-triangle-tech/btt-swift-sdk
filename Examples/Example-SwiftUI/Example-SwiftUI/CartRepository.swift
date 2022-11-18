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

struct CartProductItem: Codable, Equatable, Hashable, Identifiable {
    var id: Int
    var quantity: Int
    var product: Product

    var price: Double {
        Double(product.price).flatMap { $0 * Double(quantity) } ?? 0
    }
}

struct CartModel {
    var cart: Cart
    var items: IdentifiedArrayOf<CartProductItem>

    var subtotal: Double {
        items.reduce(into: 0) { result, element in
            result += element.price
        }
    }
}

final class CartRepository {
    private let service: Service
    private var cartDetail: CartDetail?
    let items = CurrentValueSubject<IdentifiedArrayOf<CartProductItem>, Never>([])

    init(service: Service) {
        self.service = service
    }

    @MainActor
    func add(product: Product, quantity: Int) {
        Task {
            do {
                if let item = try await addProduct(product, quantity: quantity) {
                    var currentItems = items.value
                    currentItems[id: item.id] = item
                    items.value = currentItems
                }
            } catch {
                print("ERROR: \(error)")
            }
        }
    }

    @MainActor
    func updateQuantity(cartItemID: CartItem.ID, quantity: Int) {
        guard let cartID = cartDetail?.id, let currentItem = items.value[id: cartItemID] else {
            return
        }

        Task {
            do {
                let updatedItem = try await updateItem(
                    cartItemID: cartItemID,
                    product: currentItem.product,
                    quantity: quantity)

                self.cartDetail = try await service.cart(id: cartID)

                items.value[id: cartItemID] = updatedItem

            } catch {
                print("ERROR: \(error)")
            }
        }
    }

    @MainActor
    func remove(cartItemID: CartItem.ID) {
        guard let cartID = cartDetail?.id else {
            return
        }

        Task {
            do {
                try await service.deleteCartItem(id: cartItemID)
                items.value[id: cartItemID] = nil
                cartDetail = try await service.cart(id: cartID)
            } catch {
                print("ERROR: \(error)")
            }
        }
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

    func addProduct(_ product: Product, quantity: Int = 1) async throws -> CartProductItem? {
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

    func addItem(product: Product, quantity: Int, cartID: Cart.ID) async throws -> CartProductItem {
        let cartItem = try await service.createCartItem(
            CreateCartItem(
                productID: product.id,
                quantity: quantity,
                price: product.price,
                cartID: cartID))

        return CartProductItem(
            id: cartItem.id,
            quantity: cartItem.quantity,
            product: product)
    }

    func updateItem(cartItemID: CartItem.ID, product: Product, quantity: Int) async throws -> CartProductItem {
        let cartItem = try await service.updateCartItem(
            UpdateCartItem(
                id: cartItemID,
                quantity: quantity))

        return CartProductItem(
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
