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
    }

    @MainActor
    func updateQuantity(cartItemID: CartItem.ID, quantity: Int) {
    }

    @MainActor
    func remove(cartItemID: CartItem.ID) {
    }
}

extension CartRepository {
    func add(_ product: Product, quantity: Int = 1) async throws -> CartProductItem? {
    }
}

private extension CartRepository {
    func makeCart() async throws -> Cart {
    }

    func addItem(product: Product, quantity: Int, cartID: Cart.ID) async throws -> CartProductItem {
    }

    func updateItem(cartItemID: CartItem.ID, product: Product, quantity: Int) async throws -> CartProductItem {
}

extension CartRepository {
    static var mock: CartRepository {
        .init(service: .mock)
    }
}
