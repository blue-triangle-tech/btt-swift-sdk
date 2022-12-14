//
//  CartView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import IdentifiedCollections
import SwiftUI
import Service

struct CartView: View {
    private let imageLoader: ImageLoader
    @ObservedObject var viewModel: CartViewModel

    init(imageLoader: ImageLoader, viewModel: CartViewModel) {
        self.imageLoader = imageLoader
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.productItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.fill")
                            .resizable()
                            .frame(width: 64, height: 64)

                        Text("Your cart is empty")
                    }
                    .foregroundColor(.secondary)
                } else {
                    cartList(viewModel)
                        .overlay(alignment: .bottom) {
                            Button(
                                action: {
                                    Task {
                                        await viewModel.checkout()
                                    }
                                },
                                label: {
                                    Text("Check Out")
                                })
                            .buttonStyle(.primary())
                            .padding()
                        }
                }
            }
            .onAppear {
                let timer = BlueTriangle.startTimer(
                    page: Page(
                        pageName: "Cart",
                        customNumbers: CustomNumbers(
                            cn1: viewModel.subtotal)))

                BlueTriangle.endTimer(timer)
            }
            .navigationTitle("Cart")
            .sheet(item: $viewModel.checkoutItem) { checkout in
                CheckoutView(
                    viewModel: viewModel.checkoutViewModel(checkout))
            }
        }
        .errorAlert(error: $viewModel.error)
    }
}

private extension CartView {
    func footer(estimatedTax: Double, subtotal: Double) -> some View {
        VStack(spacing: 8) {
            LineItemRow(
                title: "Estimated tax",
                value: estimatedTax)

            LineItemRow(
                title: "Subtotal",
                value: subtotal) {
                    $0.bold()
                }
        }
    }

    func cartList(_ viewModel: CartViewModel) -> some View {
        List {
            ForEach(viewModel.productItems) { productItem in
                CartItemRow(
                    imageStatusProvider: { await imageLoader.images[$0] },
                    item: productItem,
                    onIncrement: {
                        Task {
                            await viewModel.increment(id: productItem.id)
                        }
                    },
                    onDecrement: {
                        Task {
                            await viewModel.decrement(id: productItem.id)
                        }
                    })
            }

            Section {
                footer(
                    estimatedTax: viewModel.estimatedTax,
                    subtotal: viewModel.subtotal)
            }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView(
            imageLoader: .mock,
            viewModel: .init(
                service: .mock,
                cartRepository: .mock
            ))
    }
}
