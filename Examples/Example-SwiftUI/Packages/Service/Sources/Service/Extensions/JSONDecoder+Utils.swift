//
//  JSONDecoder+Utils.swift
//
//  Created by Mathew Gacy on 10/19/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601Full: JSONDecoder.DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let date = DateFormatter.iso8601Full.date(from: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Wrong Date Format")
        }
        return date
    }
}

extension JSONDecoder {
    static var iso8601Full: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601Full
        return decoder
    }
}
