//
//  CapturedRequest.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequest: Encodable, Equatable {
    enum InitiatorType: String, Encodable, Equatable {
        /// CSS
        case css
        /// HTML
        case html
        /// IFrame
        case iFrame = "iframe"
        /// Image
        case image = "img"
        /// Link
        case link
        /// Other
        case other
        /// Javascript
        case script
        /// XMLHttpRequest
        case xmlHttpRequest = "xmlhttprequest"

        // TODO: complete / expand
        init(pathExtension: String) {
            switch pathExtension {
            case "css":
                self = .css
            case "jpeg", "jpg", "png", "tif", "tiff":
                self = .image
            case "js":
                self = .script
            case "xml":
                self = .xmlHttpRequest
            default:
                self = .other
            }
        }
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

extension CapturedRequest {
    init(timer: InternalTimer, response: URLResponse?) {
        let hostComponents = response?.url?.host?.split(separator: ".") ?? []

        if hostComponents.count > 2 {
            self.domain = hostComponents.dropFirst().joined(separator: ".")
        } else {
            self.domain = response?.url?.host ?? ""
        }

        self.host = hostComponents.first != nil ? String(hostComponents.first!) : ""
        self.url = response?.url?.absoluteString ?? ""
        self.file = response?.url?.lastPathComponent ?? ""
        self.startTime = timer.relativeStartTime.milliseconds
        self.endTime = timer.relativeEndTime.milliseconds
        self.duration = timer.endTime.milliseconds - timer.startTime.milliseconds
        self.initiatorType = .init(pathExtension: response?.url?.pathExtension ?? "")
        self.decodedBodySize = 0
        self.encodedBodySize = response?.expectedContentLength ?? 0
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
