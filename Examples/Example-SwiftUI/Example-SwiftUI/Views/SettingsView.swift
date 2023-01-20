//
//  SettingsView.swift
//
//  Created by Mathew Gacy on 10/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Text("Settings")
            .onAppear {
                let timer = BlueTriangle.startTimer(
                    page: Page(
                        pageName: "Settings"))

                BlueTriangle.endTimer(timer)
            }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: .init())
    }
}
