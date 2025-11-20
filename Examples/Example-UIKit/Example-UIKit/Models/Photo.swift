//
//  Photo.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct Photo: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    var albumId: Int
    var title: String
    var url: URL
    var thumbnailUrl: URL

    init(id: Int, albumId: Int, title: String, url: URL, thumbnailUrl: URL) {
        self.id = id
        self.albumId = albumId
        self.title = title
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}

