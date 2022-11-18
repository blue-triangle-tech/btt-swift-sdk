//
//  CartItemRow.swift
//
//  Created by Mathew Gacy on 10/31/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Service
import SwiftUI

struct CartItemRow: View {
    let name: String
    let price: Double
    let quantity: Int
    let imageURL: URL
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .padding()
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo")
                        .padding()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading) {
                Text(name)
                    .multilineTextAlignment(.leading)
                    .font(.headline)

                Text(price, format: .currency(code: "USD"))

                Stepper(
                    label: {
                        Text("\(quantity)")
                    }, onIncrement: onIncrement,
                    onDecrement: onDecrement)
            }
        }
    }
}

extension CartItemRow {
    init(
        item: CartItemModel,
        onIncrement: @escaping () -> Void = {},
        onDecrement: @escaping () -> Void = {}
    ) {
        self.name = item.product.name
        self.price = item.price
        self.quantity = item.quantity
        self.imageURL = item.product.image
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
    }
}

struct CartItemRow_Previews: PreviewProvider {
    static var previews: some View {
        CartItemRow(
            item: CartItemModel(
                id: 1,
                quantity: 1,
                product: Mock.product))
            .previewLayout(.sizeThatFits)
    }
}
