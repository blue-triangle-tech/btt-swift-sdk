//
//  ProductDetailViewModel.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import Service

final class ProductDetailViewModel: ObservableObject {
    private let product: Product

    var name: String {
        product.name
    }

    init(product: Product) {
        self.product = product
    }
}
