//
//  NetworkCaptureDelegateTests.swift
//
//  Created by Mathew Gacy on 11/10/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import XCTest

@MainActor
final class NetworkCaptureDelegateTests: XCTestCase, @unchecked Sendable {

    static func makeSession() -> URLSession {
        URLSession(
            configuration: .mock,
            delegate: NetworkCaptureSessionDelegate(),
            delegateQueue: nil)
    }
}
