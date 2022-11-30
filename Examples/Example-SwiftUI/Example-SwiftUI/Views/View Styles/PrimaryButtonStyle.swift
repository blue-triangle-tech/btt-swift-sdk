//
//  PrimaryButtonStyle.swift
//
//  Created by Mathew Gacy on 10/31/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary).colorInvert()
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(color)
            )
            .compositingGroup()
            .opacity(configuration.isPressed || !isEnabled ? 0.5 : 1.0)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static func primary(color: Color = .blue) -> PrimaryButtonStyle {
        PrimaryButtonStyle(color: color)
    }
}

struct PrimaryButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Button(action: {}, label: { Text("Enabled") })
                .buttonStyle(.primary())
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Enabled")

            Button(action: {}, label: { Text("Disabled") })
                .disabled(true)
                .buttonStyle(.primary())
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Disabled")
        }
    }
}

