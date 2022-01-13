//
//  Album.swift
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct Album: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    var userId: Int
    var title: String

    init(id: Int, userId: Int, title: String) {
        self.id = id
        self.userId = userId
        self.title = title
    }
}
