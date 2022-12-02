//
//  MockTests.swift
//
//  Created by Mathew Gacy on 12/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import Service

final class MockTests: XCTestCase {
    func testMockData() throws {
        _ = Mock.cart
        _ = Mock.cartDetail
        _ = Mock.cartItem
        _ = Mock.checkout
        _ = Mock.checkoutItem
        _ = Mock.createCart
        _ = Mock.product
    }
}
