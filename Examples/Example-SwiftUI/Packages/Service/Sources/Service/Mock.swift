//
//  Mock.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

public enum Mock {}

public extension Mock {
    static var cart: Cart {
        decode(Cart.self, from: cartJSON)
    }

    static var cartDetail: CartDetail {
        decode(CartDetail.self, from: cartDetailJSON)
    }

    static var cartItem: CartItem {
        decode(CartItem.self.self, from: cartItemJSON)
    }

    static var checkout: Checkout {
        decode(Checkout.self, from: checkoutJSON)
    }

    static var checkoutItem: CheckoutItem {
        decode(CheckoutItem.self, from: checkoutItemJSON)
    }

    static var createCart: CreateCart {
        decode(CreateCart.self, from: createCartJSON)
    }

    static var product: Product {
        decode(Product.self, from: productJSON)
    }

    static func responseValue(_ jsonString: String, statusCode: Int = 200) -> ResponseValue {
        .init(
            data: Data(
                jsonString.utf8),
            httpResponse: HTTPURLResponse(
                url: Constants.baseURL,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil)!)
    }
}

extension Mock {
    static var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601Full
        return decoder
    }()

    static func decode<T: Decodable>(_ type: T.Type, from jsonString: String) -> T {
        try! decoder.decode(type, from: jsonString.data(using: .utf8)!)
    }

    static let cartJSON = """
        {"id":1,"confirmation":"","shipping":"245.67","created":"2022-09-27T15:26:10.455183Z","updated":"2022-09-27T15:26:10.455211Z","cartitem_set":[4]}
        """

    static let cartDetailJSON = """
        {"id":2,"confirmation":"","shipping":"312.98","created":"2022-09-27T15:26:10.470325Z","updated":"2022-09-27T15:26:10.470346Z","items":[{"id":3,"product":6,"quantity":999,"price":"0.99","cart":2}]}
        """

    static let cartItemJSON = """
        {"id":4,"product":3,"quantity":2,"price":"10.99","cart":1}
        """

    static let checkoutJSON = """
        {"id":2,"confirmation":"","shipping":"312.98","created":"2022-09-27T15:26:10.470325Z","updated":"2022-09-27T15:26:10.470346Z","items":[{"id":3,"product":6,"quantity":999,"price":"0.99","cart":2}]}
        """

    static let checkoutItemJSON = """
        {"id":3,"product":6,"quantity":999,"price":"0.99","cart":2}
        """

    static let createCartJSON = """
        {"confirmation":"aafdsadaeee4rtr","shipping":"10.99","cartitem_set":[1,2]}
        """

    static let productJSON = """
        {"id":1,"name":"Stuff","description":"A bunch of stuff","image":"https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse4.mm.bing.net%2Fth%3Fid%3DOIP.mjk_2I6ifdZ1thiMNX20vQHaEB%26pid%3DApi&f=1","price":"338.22"}
        """
}
