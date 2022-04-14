//
//  CapturedRequest.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequest: Encodable, Equatable {
    enum InitiatorType: String, Encodable, Equatable {
        /// Audio
        case audio
        /// Beacon
        case beacon
        /// CSS
        case css
        /// Embed
        case embed
        /// EventSource
        case eventSource = "eventsource"
        /// Fetch
        case fetch
        /// HTML
        case html
        /// Icon
        case icon
        /// IFrame
        case iFrame = "iframe"
        /// Image
        case image = "img"
        /// Input
        case input
        /// Internal
        case `internal`
        /// JSON
        case json
        /// Link
        case link
        /// Object
        case object
        /// Other
        case other
        /// Preflight
        case preflight
        /// Javascript
        case script
        /// Subdocument
        case subdocument
        /// Track
        case track
        /// Use
        case use
        /// Video
        case video
        /// ViolationReport
        case violationReport = "violationreport"
        /// XMLHttpRequest
        case xmlHttpRequest = "xmlhttprequest"
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
    enum ContentType: String, Equatable {
        // MARK: Application
        case javaArchive = "application/java-archive"
        case ediX12 = "application/EDI-X12"
        case edifact = "application/EDIFACT"
        case javascriptApplication = "application/javascript"
        case octetStream = "application/octet-stream"
        case ogg = "application/ogg"
        case pdf = "application/pdf"
        case xhtmlXML = "application/xhtml+xml"
        case flash = "application/x-shockwave-flash"
        case json = "application/json"
        case ldJSON = "application/ld+json"
        case xmlApplication = "application/xml"
        case zip = "application/zip"
        case formURLEncoded = "application/x-www-form-urlencoded"

        // MARK: Audio
        case mpegAudio = "audio/mpeg"
        case wmaAudio = "audio/x-ms-wma"
        case realAudio = "audio/vnd.rn-realaudio"
        case wav = "audio/x-wav"

        // MARK: Image
        case gif = "image/gif"
        case jpeg = "image/jpeg"
        case png = "image/png"
        case tiff = "image/tiff"
        case microsoftIcon = "image/vnd.microsoft.icon"
        case xIcon = "image/x-icon"
        case djvu = "image/vnd.djvu"
        case svgXML = "image/svg+xml"

        // MARK: Text
        case css = "text/css"
        case csv = "text/csv"
        case html = "text/html"
        case javascriptText = "text/javascript"
        case plain = "text/plain"
        case xmlText = "text/xml"

        // MARK: Video
        case mpegVideo = "video/mpeg"
        case mp4 = "video/mp4"
        case quicktime = "video/quicktime"
        case wmvVideo = "video/x-ms-wmv"
        case msvideo = "video/x-msvideo"
        case flv = "video/x-flv"
        case webm = "video/webm"
    }

    init(contentType: ContentType) {
        switch contentType {
        // MARK: Application
        case .javaArchive:
            self = .other
        case .ediX12:
            self = .other
        case .edifact:
            self = .other
        case .javascriptApplication, .javascriptText:
            self = .script
        case .octetStream:
            self = .other
        case .ogg:
            self = .other
        case .pdf:
            self = .other
        case .xhtmlXML:
            self = .other
        case .flash:
            self = .other
        case .json, .ldJSON:
            self = .json
        case .xmlApplication:
            self = .other
        case .zip:
            self = .other
        case .formURLEncoded:
            self = .other
        // MARK: Audio
        case .mpegAudio, .wmaAudio, .realAudio, .wav:
            self = .audio
        // MARK: Image
        case .gif, .jpeg, .png, .tiff, .djvu, .svgXML:
            self = .image
        case .microsoftIcon, .xIcon:
            self = .icon
        // MARK: Text
        case .css:
            self = .css
        case .csv:
            self = .other
        case .html:
            self = .html
        case .plain:
            self = .other
        case .xmlText:
            self = .other
        // MARK: Video
        case .mpegVideo, .mp4, .quicktime, .wmvVideo, .msvideo, .flv, .webm:
            self = .video
        }
    }
}

extension CapturedRequest.InitiatorType {
    enum PathExtension: String, Equatable {
        case css
        case jpeg
        case jpg
        case js
        case png
        case tif
        case tiff
        case xml
    }

    init(pathExtension: PathExtension) {
        switch pathExtension {
        case .css:
            self = .css
        case .jpeg, .jpg, .png, .tif, .tiff:
            self = .image
        case .js:
            self = .script
        case .xml:
            self = .xmlHttpRequest
        }
    }
}

extension CapturedRequest {
    init(timer: InternalTimer, response: URLResponse?) {
        let hostComponents = response?.url?.host?.split(separator: ".") ?? []
        self.host = hostComponents.first != nil ? String(hostComponents.first!) : ""
        if hostComponents.count > 2 {
            self.domain = hostComponents.dropFirst().joined(separator: ".")
        } else {
            self.domain = response?.url?.host ?? ""
        }

        if let contentType = response?.contentType {
            self.initiatorType = .init(contentType: contentType)
        } else if let pathExtension = response?.pathExtension {
            self.initiatorType = .init(pathExtension: pathExtension)
        } else {
            self.initiatorType = .other
        }

        self.url = response?.url?.absoluteString ?? ""
        self.file = response?.url?.lastPathComponent ?? ""
        self.startTime = timer.relativeStartTime.milliseconds
        self.endTime = timer.relativeEndTime.milliseconds
        self.duration = timer.endTime.milliseconds - timer.startTime.milliseconds
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
