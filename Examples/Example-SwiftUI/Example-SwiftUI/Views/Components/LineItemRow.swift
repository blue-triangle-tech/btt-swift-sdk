//
//  LineItemRow.swift
//
//  Created by Mathew Gacy on 12/1/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import SwiftUI

struct LineItemRow<ModifiedTitle: View>: View {
    let title: String
    let value: Double
    let currencyCode: String
    let titleModifier: (Text) -> ModifiedTitle

    init(
        title: String,
        value: Double,
        currencyCode: String = Constants.currencyCode,
        @ViewBuilder titleModifier: @escaping (Text) -> ModifiedTitle = { $0 }
    ) {
        self.title = title
        self.currencyCode = currencyCode
        self.value = value
        self.titleModifier = titleModifier
    }

    public var body: some View {
        HStack {
            titleModifier(Text(title))

            Spacer()

            Text(
                value,
                format: .currency(
                    code: currencyCode))
        }
    }
}

struct LineItemRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LineItemRow(
                title: "Title",
                value: 9.99) {
                    $0.bold()
                }

            LineItemRow(
                title: "Title",
                value: 9.99)
        }
        .previewLayout(.sizeThatFits)
    }
}
