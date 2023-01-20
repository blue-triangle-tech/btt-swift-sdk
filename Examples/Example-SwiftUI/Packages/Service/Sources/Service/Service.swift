//
//  Service.swift
//
//  Created by Mathew Gacy on 10/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public struct Service {

    enum Route {
        /// Path: `/cart/{cart_id}/`
        case cart(Cart.ID)
        /// Path: `/cart/{cart_id}/checkout/`
        case cartCheckout(Checkout.ID)
        /// Path: `/cart/`
        case carts
        /// Path: `/item/{item_id}/`
        case item(CartItem.ID)
        /// Path: `/item/`
        case items
        /// Path: `/products/{product_id}/`
        case product(Product.ID)
        /// Path: `/products/`
        case products

        var path: String {
            switch self {
            case .cart(let id):
                return "/cart/\(id)/"
            case .cartCheckout(let id):
                return "/cart/\(id)/checkout/"
            case .carts:
                return "/cart/"
            case .item(let id):
                return "/item/\(id)/"
            case .items:
                return "/item/"
            case .product(let id):
                return "/product/\(id)/"
            case .products:
                return "/product/"
            }
        }
    }

    private let baseURL: URL
    private let decoder: JSONDecoder = .iso8601Full
    private let networking: (URLRequest) async throws -> ResponseValue

    public init(
        baseURL: URL,
        networking: @escaping (URLRequest) async throws -> ResponseValue
    ) {
        self.baseURL = baseURL
        self.networking = networking
    }

    public func carts() async throws -> [Cart] {
        try await networking(.get(url(for: .carts)))
            .validate()
            .decode(with: decoder)
    }

    public func cart(id: Cart.ID) async throws -> CartDetail {
        try await networking(.get(url(for: .cart(id))))
            .validate()
            .decode(with: decoder)
    }

    public func checkout(id: Checkout.ID) async throws -> Checkout {
        try await networking(.get(url(for: .cartCheckout(id))))
            .validate()
            .decode(with: decoder)
    }

    public func createCart(_ createCart: CreateCart) async throws -> Cart {
        try await networking(.post(url(for: .carts), body: createCart))
            .validate()
            .decode(with: decoder)
    }

    public func createCartItem(_ createCartItem: CreateCartItem) async throws -> CartItem {
        try await networking(.post(url(for: .items), body: createCartItem))
            .validate()
            .decode(with: decoder)
    }

    public func updateCartItem(_ updateCartItem: UpdateCartItem) async throws -> CartItem {
        try await networking(.patch(url(for: .item(updateCartItem.id)), body: updateCartItem))
            .validate()
            .decode(with: decoder)
    }

    public func deleteCartItem(id: CartItem.ID) async throws -> Void {
        try await networking(.delete(url(for: .item(id))))
            .validate()
    }

    public func deleteCheckout(id: Checkout.ID) async throws -> CartDetail {
        try await networking(.delete(url(for: .cartCheckout(id))))
            .validate()
            .decode(with: decoder)
    }

    public func items() async throws -> [CartItem] {
        try await networking(.get(url(for: .items)))
            .validate()
            .decode(with: decoder)
    }

    public func product(id: Product.ID) async throws -> Product {
        try await networking(.get(url(for: .product(id))))
            .validate()
            .decode(with: decoder)
    }

    public func products() async throws -> [Product] {
        try await networking(.get(url(for: .products)))
            .validate()
            .decode(with: decoder)
    }
}

public extension Service {
    static let live: Self = {
        let session = URLSession(configuration: .default)

        return .init(
            baseURL: Constants.baseURL,
            networking: session.data(request:))
    }()

    static let mock: Self = {
        .init(
            baseURL: Constants.baseURL,
            networking: NetworkingMock.networking)
    }()
}

private extension Service {
    func url(for route: Route) -> URL {
        baseURL.appendingPathComponent(route.path)
    }
}
