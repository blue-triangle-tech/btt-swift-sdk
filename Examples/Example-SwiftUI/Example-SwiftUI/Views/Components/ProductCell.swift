//
//  ProductCell.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Service
import SwiftUI

struct ProductCell: View {
    let name: String
    let price: String
    let imageURL: URL

    var body: some View {
        VStack {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Image(systemName: "photo")
                        .padding()
                @unknown default:
                    EmptyView()
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .bold()
                        .multilineTextAlignment(.leading)

                    Text(price)
                }

                Spacer()
            }
            .foregroundColor(.primary)
        }
    }
}

extension ProductCell {
    init(product: Product) {
        self.name = product.name
        self.price = "$\(product.price)"
        self.imageURL = product.image
    }
}

struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(
            product: Mock.product)
        .previewLayout(.sizeThatFits)
    }
}
