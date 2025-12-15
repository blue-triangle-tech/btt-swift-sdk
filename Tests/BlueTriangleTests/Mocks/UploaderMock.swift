//
//  UploaderMock.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Foundation

struct UploaderMock: Uploading, @unchecked Sendable {
    var onSend: (Request) -> Void = { _ in }

    init(onSend: @escaping (Request) -> Void = { _ in }) {
        self.onSend = onSend
    }

    func send(request: Request) {
        onSend(request)
    }
}
