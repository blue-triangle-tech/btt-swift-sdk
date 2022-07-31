//
//  LabeledView.swift
//  TimerRequest
//
//  Created by Mathew Gacy on 7/31/22.
//

import SwiftUI

struct LabeledView<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(.accentColor)
                .font(.caption)

            content
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

struct LabeledView_Previews: PreviewProvider {
    static var previews: some View {
        LabeledView("Example") {
            TextField("", text: .constant("Lorem ipsum"))
        }
    }
}
