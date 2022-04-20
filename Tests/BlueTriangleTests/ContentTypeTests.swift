//
//  ContentTypeTests.swift
//
//  Created by Mathew Gacy on 4/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class ContentTypeTests: XCTestCase {
    typealias ContentType = HTTPURLResponse.ContentType

    func testMissingContentType() throws {
        let contentType = ""
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let actual = response.contentType
        XCTAssertNil(actual)
    }

    func testMalformedContentType() throws {
        let contentType = "application/"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let actual = response.contentType
        XCTAssertNil(actual)
    }

    func testInvalidMediaType() throws {
        let contentType = "foo/xml"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let actual = response.contentType
        XCTAssertNil(actual)
    }

    func testInvalidString() throws {
        let contentType = "foo/bar/xml"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let actual = response.contentType
        XCTAssertNil(actual)
    }

    func testCharset() throws {
        let contentType = "application/json;charset=UTF-8"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let expected: ContentType = (mediaType: .application, mediaSubtype: "json", parameters: "charset=utf-8")
        let actual = response.contentType!
        XCTAssertTrue(expected == actual)
    }

    func testCharsetWithSpace() throws {
        let contentType = "application/json; charset=UTF-8"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let expected: ContentType = (mediaType: .application, mediaSubtype: "json", parameters: "charset=utf-8")
        let actual = response.contentType!
        XCTAssertTrue(expected == actual)
    }

    func testApplicationWithSuffix() throws {
        let contentType = "application/ld+json"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let expected: ContentType = (mediaType: .application, mediaSubtype: "ld+json", parameters: nil)
        let actual = response.contentType!
        XCTAssertTrue(expected == actual)
    }

    func testWithoutCharset() throws {
        let contentType = "audio/mpeg"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let expected: ContentType = (mediaType: .audio, mediaSubtype: "mpeg", parameters: nil)
        let actual = response.contentType
        XCTAssertTrue(expected == actual!)
    }

    func testMediaType3() throws {
        let contentType = "text/css"
        let response = Mock.makeHTTPResponse(headerFields: ["Content-Type": contentType])

        let expected: ContentType = (mediaType: .text, mediaSubtype: "css", parameters: nil)
        let actual = response.contentType!
        XCTAssertTrue(expected == actual)
    }
}
