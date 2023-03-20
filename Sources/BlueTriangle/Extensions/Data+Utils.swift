//
//  Data+Utils.swift
//
//  Created by Mathew Gacy on 9/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Data {
    var prettyJson: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = String(data: data, encoding: .utf8) else {
            return nil
        }

        return prettyPrintedString
    }

    func base64DecodedData(options: Data.Base64DecodingOptions = []) -> Data? {
        Data(base64Encoded: self, options: options)
    }
}
