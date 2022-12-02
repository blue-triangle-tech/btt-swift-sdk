//
//  CheckoutViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class CheckoutViewModel: ObservableObject {
    private let cartRepository: CartRepository
    private let onFinish: () -> Void
    @Published var checkout: Checkout
    @Published var error: Error?

    var estimatedTax: Double {
        Constants.averageSalesTax * itemTotal
    }

    var itemCount: Int {
        checkout.items.reduce(into: 0) { count, item in
            count += item.quantity
        }
    }

    var itemTotal: Double {
        checkout.items.reduce(into: 0) { result, item in
            result += Double(item.price).flatMap { $0 * Double(item.quantity) } ?? 0
        }
    }

    var shipping: Double {
        0.0
    }

    var total: Double {
        estimatedTax + shipping + itemTotal
    }

    init(
        cartRepository: CartRepository,
        checkout: Checkout,
        onFinish: @escaping () -> Void
    ) {
        self.cartRepository = cartRepository
        self.checkout = checkout
        self.onFinish = onFinish
    }

    func placeOrder() async {
        do {
            _ = try await cartRepository.confirm(checkout.id)
            onFinish()
        } catch {
            self.error = error
        }
    }
}
