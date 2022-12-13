//
//  ProductCell.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Service
import SwiftUI

struct ProductCell: View {
    @State var imageStatus: ImageStatus?
    let imageStatusProvider: (URL) async -> ImageStatus?
    let name: String
    let price: String
    let imageURL: URL

    var body: some View {
        VStack {
            if let imageStatus {
                RemoteImage(imageStatus: imageStatus)
                    .cornerRadius(8)
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
        .task {
            if let status = await imageStatusProvider(imageURL) {
                imageStatus = status
            }
        }
    }
}

extension ProductCell {
    init(
        imageStatusProvider: @escaping (URL) async -> ImageStatus?,
        product: Product
    ) {
        self.imageStatusProvider = imageStatusProvider
        self.name = product.name
        self.price = "$\(product.price)"
        self.imageURL = product.image
    }
}

struct ProductCell_Previews: PreviewProvider {
    static var previews: some View {
        ProductCell(
            imageStatusProvider: { _ in
                .downloaded(.success(UIColor.random().image()))
            },
            product: Mock.product
        )
        .previewLayout(.sizeThatFits)
    }
}
