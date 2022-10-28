//
//  TabContainerView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Service
import SwiftUI

struct TabContainerView: View {
    enum Tab: Hashable {
        case products
        case cart
        case settings
    }

    private let service: Service
    @State private var selectedTab: Tab = .products

    init(service: Service) {
        self.service = service
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductListView(
                viewModel: .init(
                    service: service))
                .tabItem {
                    Text("Products")
                    Image(systemName: "square.grid.2x2.fill")
                 }
                .tag(Tab.products)

            CartView(viewModel: .init())
                .tabItem {
                    Text("Cart")
                    Image(systemName: "cart.fill")
                 }
                .tag(Tab.cart)

            SettingsView(viewModel: .init())
                .tabItem {
                    Text("Settings")
                    Image(systemName: "gearshape.fill")
                 }
                .tag(Tab.settings)
        }
    }
}

struct TabContainerView_Previews: PreviewProvider {
    static var previews: some View {
        TabContainerView(service: .mock)
    }
}
