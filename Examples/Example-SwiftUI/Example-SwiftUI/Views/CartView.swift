//
//  CartView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import IdentifiedCollections
import SwiftUI
import Service

struct CartView: View {
    @StateObject var viewModel: CartViewModel

    init(viewModel: CartViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Cart")
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView(
            viewModel: .init(
                service: .mock,
                cartRepository: .mock
            ))
    }
}
