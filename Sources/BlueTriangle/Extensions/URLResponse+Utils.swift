//
//  URLResponse+Utils.swift
//
//  Created by Mathew Gacy on 4/13/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLResponse {
    var contentType: CapturedRequest.InitiatorType.ContentType? {
        guard let httpResponse = self as? HTTPURLResponse,
              let contentTypeValue = httpResponse.value(forHTTPHeaderField: "Content-Type"),
              let contentTypeString = contentTypeValue.split(separator: ";")
                .first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() else {
            return nil
        }
        return .init(rawValue: contentTypeString)
    }

    var pathExtension: CapturedRequest.InitiatorType.PathExtension? {
        guard let pathExtensionString = url?.pathExtension else {
            return nil
        }
        return .init(rawValue: pathExtensionString)
    }
}
