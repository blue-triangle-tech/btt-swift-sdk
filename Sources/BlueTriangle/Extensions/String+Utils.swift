//
//  String+Utils.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/02/26.
//

import Foundation

extension String {
    func matchesWildcard(_ pattern: String) -> Bool {
        let keyword = pattern.replacingOccurrences(of: "*", with: "")
        return self.localizedCaseInsensitiveContains(keyword)
    }
}
