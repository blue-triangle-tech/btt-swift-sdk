//
//  ProductListView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Service
import SwiftUI

struct ProductListView: View {
    enum Route: Hashable {
        case productDetail(Product)
    }

    @StateObject var viewModel: ProductListViewModel

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 170))]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(alignment: .top) {
                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.products.0) { product in
                            NavigationLink(value: product) {
                                ProductCell(product: product)
                            }
                        }
                    }

                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.products.1) { product in
                            NavigationLink(value: product) {
                                ProductCell(product: product)
                            }
                        }
                    }
                }
                .navigationDestination(for: Product.self) { product in
                    if let detailViewModel = viewModel.detailViewModel(for: product.id) {
                        ProductDetailView(
                            viewModel: detailViewModel)
                    } else {
                        Text("Error")
                    }
                }
            }
            .task {
                await viewModel.loadProducts()
            }
            .navigationTitle("Products")
        }
        .errorAlert(error: $viewModel.error)
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView(viewModel: .init(service: .mock))
    }
}
