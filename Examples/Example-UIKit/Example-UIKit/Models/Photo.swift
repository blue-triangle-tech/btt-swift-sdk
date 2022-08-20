//
//  Photo.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 1/7/22.
//

import Foundation

struct Photo: Codable, Identifiable, Equatable, Hashable {
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

