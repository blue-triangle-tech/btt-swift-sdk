//
//  File.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

enum NetworkingMock {
    static func networking(_ request: URLRequest) async throws -> ResponseValue {
        guard let url = request.url else {
            throw NetworkError.malformedRequest
        }

        let jsonString: String
        switch url.lastPathComponent {
        case "cart":
            jsonString = jsonArray(with: Mock.cartJSON)
        case "checkout":
            jsonString = Mock.checkoutJSON
        case "item":
            jsonString = jsonArray(with: Mock.cartItemJSON)
        case "product":
            jsonString = jsonArray(with: Mock.productJSON)
        default:
            if url.pathComponents.contains("cart") {
                jsonString = Mock.cartDetailJSON
            } else if url.pathComponents.contains("product") {
                jsonString = Mock.productJSON
            } else {
                throw NetworkError.malformedRequest
            }   
        }

        return Mock.responseValue(jsonString)
    }

    private static func jsonArray(with elementString: String) -> String {
        "[\(elementString)]"
    }
}
