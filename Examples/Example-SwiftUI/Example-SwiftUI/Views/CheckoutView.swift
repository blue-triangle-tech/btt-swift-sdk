//
//  CheckoutView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var  viewModel: CheckoutViewModel
    init(viewModel: CheckoutViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Checkout")
    }
}

struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutView(
            viewModel: .init(
                cartRepository: .mock,
                checkout: Mock.checkout,
                onFinish: {}
            ))
    }
}
