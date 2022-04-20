//
//  File.swift
//
//  Created by Mathew Gacy on 4/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class InitiatorTypeTests: XCTestCase {
    typealias ContentType = HTTPURLResponse.ContentType
    typealias InitiatorType = CapturedRequest.InitiatorType
    typealias PathExtension = InitiatorType.PathExtension
    typealias MediaSubtype = InitiatorType.MediaSubtype
}

// MARK: - ContentType
extension InitiatorTypeTests {
    func testApplicationMediaTypeWithRecognizedSubtypeSuffix() throws {
        let contentType: ContentType = (mediaType: .application, mediaSubtype: "alto-endpointprop+json", parameters: "charset=utf-8")

        let expected: InitiatorType? = .json
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testApplicationMediaTypeWithUnecognizedSubtypeSuffix() throws {
        let contentType: ContentType = (mediaType: .application, mediaSubtype: "at+jwt", parameters: "charset=utf-8")

        let expected: InitiatorType? = .none
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testApplicationMediaTypeWithRecognizedSubtype() throws {
        let contentType: ContentType = (mediaType: .application, mediaSubtype: "json", parameters: "charset=utf-8")

        let expected: InitiatorType? = .json
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testApplicationMediaTypeWithUnecognizedSubtype() throws {
        let contentType: ContentType = (mediaType: .application, mediaSubtype: "java-archive", parameters: "charset=utf-8")

        let expected: InitiatorType? = .none
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testTextMediaTypeWithRecognizedSubtype() throws {
        let contentType: ContentType = (mediaType: .text, mediaSubtype: "html", parameters: "charset=utf-8")

        let expected: InitiatorType? = .html
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testTextMediaTypeWithUnecognizedSubtype() throws {
        let contentType: ContentType = (mediaType: .text, mediaSubtype: "csv-schema", parameters: "charset=utf-8")

        let expected: InitiatorType? = .none
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testOtherMediaType() throws {
        let contentType: ContentType = (mediaType: .image, mediaSubtype: "png", parameters: nil)

        let expected: InitiatorType? = .image
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }

    func testOtherMediaTypeWithSuffix() throws {
        let contentType: ContentType = (mediaType: .image, mediaSubtype: "svg+xml", parameters: nil)

        let expected: InitiatorType? = .image
        let actual: InitiatorType? = .init(contentType)
        XCTAssertEqual(expected, actual)
    }
}

// MARK: - MediaSubtype
extension InitiatorTypeTests {
    func testInitWithMediaSubtype() throws {
        MediaSubtype.allCases.forEach { subtype in
            let actual = InitiatorType(subtype)
            XCTAssertNotNil(actual)
        }
    }
}

// MARK: - Path Extension
extension InitiatorTypeTests {
    func testInitWithPathExtension() throws {
        PathExtension.allCases.forEach { pathExtension in
            let actual = InitiatorType(pathExtension)
            XCTAssertNotNil(actual)
        }
    }
}
