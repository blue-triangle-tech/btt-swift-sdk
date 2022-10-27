//
//  TabContainerView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

struct TabContainerView: View {
    enum Tab: Hashable {
        case products
        case cart
        case settings
    }

    @State private var selectedTab: Tab = .products

    var body: some View {
        TabView(selection: $selectedTab) {
            ProductListView(viewModel: .init())
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
        TabContainerView()
    }
}
