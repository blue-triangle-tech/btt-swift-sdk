//
//  HTTPURLResponse+ContentType.swift
//
//  Created by Mathew Gacy on 4/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    /// Representation of IANA media types. See https://www.iana.org/assignments/media-types/media-types.xhtml.
    enum MediaType: String, Equatable {
        case application
        case audio
        case example
        case font
        case image
        case message
        case model
        case multipart
        case text
        case video
    }

    typealias ContentType = (mediaType: MediaType, mediaSubtype: String, parameters: String?)

    var contentType: ContentType? {
        guard let contentTypeValue = value(forHTTPHeaderField: "Content-Type") else {
            return nil
        }

        let components = contentTypeValue
            .lowercased()
            .split(separator: ";")
            .flatMap { $0.split(separator: "/") }
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard let mediaTypeString = components.first, let mediaType = MediaType(rawValue: mediaTypeString) else {
            return nil
        }

        switch components.count {
        case 3:
            return (mediaType: mediaType, mediaSubtype: components[1], parameters: components[2])
        case 2:
            return (mediaType: mediaType, mediaSubtype: components[1], parameters: nil)
        default:
            return nil
        }
    }
}
