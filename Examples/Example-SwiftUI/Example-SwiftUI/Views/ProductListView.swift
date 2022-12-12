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

    @ObservedObject var viewModel: ProductListViewModel

    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
    }

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 150, maximum: 170))]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                HStack(alignment: .top, spacing: 16) {
                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.products.0) { product in
                            NavigationLink(value: product) {
                                ProductCell(
                                    imageStatusProvider: viewModel.imageStatus(_:),
                                    product: product)
                            }
                        }
                    }

                    LazyVGrid(columns: columns) {
                        ForEach(viewModel.products.1) { product in
                            NavigationLink(value: product) {
                                ProductCell(
                                    imageStatusProvider: viewModel.imageStatus(_:),
                                    product: product)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .navigationDestination(for: Product.self) { product in
                    if let detailViewModel = viewModel.detailViewModel(for: product.id) {
                        ProductDetailView(
                            viewModel: detailViewModel)
                    } else {
                        Text("Error")
                    }
                }
            }
            .refreshable {
                await viewModel.loadProducts()
            }
            .task {
                await viewModel.onAppear()
            }
            .navigationTitle("Products")
        }
        .errorAlert(error: $viewModel.error)
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView(
            viewModel: .init(
                cartRepository: .mock,
                imageLoader: .mock,
                service: .mock))
    }
}
