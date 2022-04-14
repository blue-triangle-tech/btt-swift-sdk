//
//  URLResponse+Utils.swift
//
//  Created by Mathew Gacy on 4/13/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLResponse {
    var headerFields: [String: String]? {
        guard let httpResponse = self as? HTTPURLResponse else {
            return nil
        }
        return httpResponse.allHeaderFields as? [String: String]
    }

    var contentType: CapturedRequest.InitiatorType.ContentType? {
        guard let contentTypeString = headerFields?["Content-Type"] else {
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
