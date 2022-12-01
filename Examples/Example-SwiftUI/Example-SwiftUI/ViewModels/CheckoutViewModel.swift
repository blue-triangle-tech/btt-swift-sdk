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

    init(
        cartRepository: CartRepository,
        checkout: Checkout,
        onFinish: @escaping () -> Void
    ) {
        self.cartRepository = cartRepository
        self.checkout = checkout
        self.onFinish = onFinish
    }

    func placeOrder() {
        onFinish()
    }
}
