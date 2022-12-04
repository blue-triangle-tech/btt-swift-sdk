//
//  RemoteImage.swift
//
//  Created by Mathew Gacy on 11/28/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

struct RemoteImage: View {
    let contentMode: ContentMode = .fit
    let imageStatus: ImageStatus?

    var body: some View {
        switch imageStatus {
        case .downloaded(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .cornerRadius(8)
        case .error:
            Image(systemName: "exclamationmark.circle")
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .foregroundColor(.red)
                .padding()
        default:
            ProgressView()
                .padding()
        }
    }
}
