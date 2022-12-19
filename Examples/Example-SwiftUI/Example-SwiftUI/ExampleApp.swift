//
//  ExampleApp.swift
//  Example-SwiftUI
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import SwiftUI

@main
struct Example_SwiftUIApp: App {
    init() {
        BlueTriangle.configure { config in
            config.siteID = Secrets.siteID
            config.networkSampleRate = 1.0
            // ...
        }
    }

    var body: some Scene {
        WindowGroup {
            TabContainerView(
                imageLoader: .live,
                service: .captured)
        }
    }
}
