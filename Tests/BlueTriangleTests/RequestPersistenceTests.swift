//
//  RequestPersistenceTests.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest
@testable import BlueTriangle

final class RequestPersistenceTests: XCTestCase {
    struct Model: Codable {
        var id: Int
    }

    static var file: File {
        let fileLocation = UserLocation.document(Constants.persistenceDirectory)
        let file = File(fileLocation: fileLocation, name: "test")!
        return file
    }

    static var persistence: Persistence {
        Persistence(file: Self.file)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        do {
            try FileManager.default.removeItem(at: Self.file.url)
        } catch CocoaError.Code.fileNoSuchFile {
            return
        } catch {
            throw error
        }
    }

    func testRequestPersistenceBuffer() throws {
        let maxSize: Int = 1024 * 1024
        let logger = LoggerMock(onError: { XCTFail("Unexpected error: \($0)") })

        var sut = RequestPersistence(persistence: Self.persistence, logger: logger, maxSize: maxSize)

        let request1 = try Request(url: Constants.timerEndpoint, model: Model(id: 1), encode: { try JSONEncoder().encode($0) })
        sut.save(request1)

        let request2 = try Request(url: Constants.timerEndpoint, model: Model(id: 2), encode: { try JSONEncoder().encode($0) })
        sut.save(request2)

        let requests = try sut.read()
        XCTAssertEqual(requests, [request1, request2])
    }

    func testRequestPersistenceFile() throws {
        let maxSize: Int = 100
        let logger = LoggerMock(onError: { XCTFail("Unexpected error: \($0)") })

        var sut = RequestPersistence(persistence: Self.persistence, logger: logger, maxSize: maxSize)

        let request1 = try Request(url: Constants.timerEndpoint, model: Model(id: 1), encode: { try JSONEncoder().encode($0) })
        sut.save(request1)

        let request2 = try Request(url: Constants.timerEndpoint, model: Model(id: 2), encode: { try JSONEncoder().encode($0) })
        sut.save(request2)

        XCTAssert(FileManager.default.fileExists(atPath: Self.file.path))

        let requests = try sut.read()
        XCTAssertEqual(requests, [request1, request2])
    }
}
