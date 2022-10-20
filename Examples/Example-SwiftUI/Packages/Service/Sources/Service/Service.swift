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
        case cart(Int)
        /// Path: `/cart/{cart_id}/checkout/`
        case cartCheckout(Checkout.ID)
        /// Path: `/cart/`
        case carts
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
    private let decoder: JSONDecoder
    private let networking: (URLRequest) async throws -> ResponseValue

    public init(
        baseURL: URL,
        decoder: JSONDecoder,
        networking: @escaping (URLRequest) async throws -> ResponseValue
    ) {
        self.baseURL = baseURL
        self.decoder = decoder
        self.networking = networking
    }

    public func carts() async throws -> [Cart] {
        try await networking(.get(url(for: .carts)))
            .validate()
            .decode(with: decoder)
    }

    public func checkout(id: Checkout.ID) async throws -> Checkout {
        try await networking(.get(url(for: .cartCheckout(id))))
            .validate()
            .decode(with: decoder)
    }

    public func createCart(_ createCart: CreateCart) async throws -> Cart {
        try await networking(.post(url(for: Route.carts), body: createCart))
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
        var decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601Full

        let session = URLSession(configuration: .default)

        return .init(
            baseURL: Constants.baseURL,
            decoder: decoder,
            networking: session.data(request:))
    }()
}

private extension Service {
    func url(for route: Route) -> URL {
        baseURL.appendingPathComponent(route.path)
    }
}
