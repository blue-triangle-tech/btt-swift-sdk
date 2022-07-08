//
//  PersistenceTests.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import XCTest
@testable import BlueTriangle

final class PersistenceTests: XCTestCase {
    struct Model: Codable, Equatable {
        var value: String
    }

    var file: File = {
        let fileLocation = UserLocation.document(Constants.persistenceDirectory)
        let file = try! File(fileLocation: fileLocation, name: "test")
        return file
    }()

    override func tearDownWithError() throws {
        super.tearDown()
        do {
            try FileManager.default.removeItem(at: file.url)
        } catch CocoaError.Code.fileNoSuchFile {
            return
        } catch {
            throw error
        }
    }

    func testWrite() throws {
        let sut = Persistence(file: file)
        let data = Data(Date().description.utf8)
        try sut.write(data)

        let actual = try Data(contentsOf: file.url)
        XCTAssertEqual(actual, data)
    }

    func testAppend() throws {
        let sut = Persistence(file: file)

        let firstLine = Date().description
        try sut.append(Data(firstLine.utf8))

        let secondLine = Date().description
        try sut.append(Data(secondLine.utf8))

        let thirdLine = Date().description
        try sut.append(Data(thirdLine.utf8))

        let data = try sut.readData()!
        let actual = String(decoding: data, as: UTF8.self)
        let expected = [firstLine, secondLine, thirdLine].joined()

        XCTAssertEqual(expected, actual)
    }

    func testReadData() throws {
        try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
        let data = Data(Date().description.utf8)
        try data.write(to: file.url)

        let sut = Persistence(file: file)
        let actual = try sut.readData()
        XCTAssertEqual(actual, data)
    }

    func testClear() throws {
        let sut = Persistence(file: file)
        let data = Data(Date().description.utf8)

        try sut.write(data)
        XCTAssert(FileManager.default.fileExists(atPath: file.path))

        try sut.clear()

        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))

        try sut.clear()
    }

    func testSaveAndRead() throws {
        let sut = Persistence(file: file)
        let model = Model(value: Date().description)

        try sut.save(model)

        let actual: Model? = try sut.read()
        XCTAssertEqual(actual, model)
    }
}
