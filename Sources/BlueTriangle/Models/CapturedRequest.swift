//
//  CapturedRequest.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequest: Encodable, Equatable {
    /// Representation of field type.
    enum InitiatorType: String, Encodable, Equatable {
        // Unprocessed IANA media types (excludes `application` and `text`)
        case audio
        case example
        case font
        case image
        case message
        case model
        case multipart
        case video
        // Derived from IANA media subtypes
        case css
        case csv
        case html
        case javascript
        case json
        case xml
        case zip
        // Fallback
        case other
    }

    let entryType = "resource"
    /// Page domain without host.
    var domain: String
    /// Subdomain of the fully qualified domain name.
    var host: String
    /// Full URL.
    var url: String
    /// Name of the file.
    var file: String?
    /// Request start time.
    var startTime: Millisecond
    /// Request end time.
    var endTime: Millisecond
    /// Request duration.
    var duration: Millisecond
    /// The type of field being returned.
    var initiatorType: InitiatorType
    /// Compressed size of content.
    var decodedBodySize: Int64
    /// Decompressed size of content.
    var encodedBodySize: Int64
}

extension CapturedRequest.InitiatorType {
    init?(_ contentType: HTTPURLResponse.ContentType) {
        switch contentType.mediaType {
        case .application:
            guard let suffix = contentType.mediaSubtype.split(separator: "+").last,
                  let subtype = MediaSubtype(rawValue: String(suffix)) else {
                return nil
            }
            self.init(subtype)
        case .text:
            guard let subtype = MediaSubtype(rawValue: contentType.mediaSubtype) else {
                return nil
            }
            self.init(subtype)
        default:
            self.init(contentType.mediaType)
        }
    }
}

extension CapturedRequest.InitiatorType {
    init?(_ mediaType: HTTPURLResponse.MediaType) {
        self.init(rawValue: mediaType.rawValue)
    }
}

extension CapturedRequest.InitiatorType {
    enum MediaSubtype: String, Equatable, CaseIterable {
        case css
        case csv
        case html
        case javascript
        case json
        case xml
        case zip
    }

    init?(_ mediaSubtype: MediaSubtype) {
        self.init(rawValue: mediaSubtype.rawValue)
    }
}

extension CapturedRequest.InitiatorType {
    // swiftlint:disable identifier_name
    enum PathExtension: String, Equatable, CaseIterable {
        case css
        case html
        case jpeg
        case jpg
        case js
        case png
        case tif
        case tiff
        case xml
    }
    // swiftlint:enable identifier_name

    init?(_ pathExtension: PathExtension) {
        switch pathExtension {
        case .css:
            self = .css
        case .html:
            self = .html
        case .jpeg, .jpg, .png, .tif, .tiff:
            self = .image
        case .js:
            self = .javascript
        case .xml:
            self = .xml
        }
    }
}

extension CapturedRequest {
    init(timer: InternalTimer, relativeTo startTime: Millisecond, response: URLResponse?) {
        self.init(
            startTime: timer.startTime.milliseconds - startTime,
            endTime: timer.endTime.milliseconds - startTime,
            duration: timer.endTime.milliseconds - timer.startTime.milliseconds,
            decodedBodySize: response?.expectedContentLength ?? 0,
            encodedBodySize: 0,
            response: response)
    }

    init(metrics: URLSessionTaskMetrics, relativeTo startTime: Millisecond) {
        let lastMetric = metrics.transactionMetrics.last

        self.init(
            startTime: metrics.taskInterval.start.timeIntervalSince1970.milliseconds - startTime,
            endTime: metrics.taskInterval.end.timeIntervalSince1970.milliseconds - startTime,
            duration: metrics.taskInterval.duration.milliseconds,
            decodedBodySize: lastMetric?.countOfResponseBodyBytesAfterDecoding ?? 0,
            encodedBodySize: lastMetric?.countOfResponseBodyBytesReceived ?? 0,
            response: lastMetric?.response)
    }

    init(
        startTime: Millisecond,
        endTime: Millisecond,
        duration: Millisecond,
        decodedBodySize: Int64,
        encodedBodySize: Int64,
        response: URLResponse?
    ) {
        let hostComponents = response?.url?.host?.split(separator: ".") ?? []
        self.host = hostComponents.first != nil ? String(hostComponents.first!) : ""
        if hostComponents.count > 2 {
            self.domain = hostComponents.dropFirst().joined(separator: ".")
        } else {
            self.domain = response?.url?.host ?? ""
        }

        if let httpResponse = response as? HTTPURLResponse, let contentType = httpResponse.contentType {
            self.initiatorType = .init(contentType) ?? .other
        } else if let pathExtensionString = response?.url?.pathExtension,
                  let pathExtension = InitiatorType.PathExtension(rawValue: pathExtensionString) {
            self.initiatorType = .init(pathExtension) ?? .other
        } else {
            self.initiatorType = .other
        }

        self.url = response?.url?.absoluteString ?? ""
        self.file = response?.url?.lastPathComponent ?? ""
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.decodedBodySize = decodedBodySize
        self.encodedBodySize = encodedBodySize
    }
}

// MARK: - Supporting Types
extension CapturedRequest {
    enum CodingKeys: String, CodingKey {
        case entryType = "e"
        case domain = "dmn"
        case host = "h"
        case url = "URL"
        case file = "f"
        case startTime = "sT"
        case endTime = "rE"
        case duration = "d"
        case initiatorType = "i"
        case decodedBodySize = "dz"
        case encodedBodySize = "ez"
    }
}

// MARK: - CustomStringConvertible
extension CapturedRequest: CustomStringConvertible {
    var description: String {
        "CapturedRequest(url: \(url), startTime: \(startTime))"
    }
}
