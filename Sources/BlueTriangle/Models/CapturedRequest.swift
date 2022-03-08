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
    /// Reuest start time.
    var startTime: Millisecond
    /// Request duration.
    var duration: Millisecond
    /// The type of field being returned.
    var initiatorType: InitiatorType
    /// Compressed size of content.
    var decodedBodySize: Int
    /// Decompressed size of content.
    var encodedBodySize: Int
}

// MARK: - Supporting Types
extension CapturedRequest {
    enum CodingKeys: String, CodingKey {
        case entryType = "e"
        case domain = "dmn"
        case file = "f"
        case duration = "d"
        case initiatorType = "i"
        case host = "h"
        case decodedBodySize = "dz"
        case encodedBodySize = "Ez"
    }
}
