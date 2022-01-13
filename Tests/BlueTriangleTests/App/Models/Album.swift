//
//  Album.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 1/7/22.
//

import Foundation

struct Album: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    var userId: Int
    var title: String

    public init(id: Int, userId: Int, title: String) {
        self.id = id
        self.userId = userId
        self.title = title
    }
}
