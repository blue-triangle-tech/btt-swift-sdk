//
//  JSONPlaceholder.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//

import Foundation

struct JSONPlaceholder: PlaceholderServiceProtocol {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func fetchAlbums() async throws -> [Album] {
        let url = URL(string: "https://jsonplaceholder.typicode.com/albums")!
        let data = try await session.btData(from: url)
        return try JSONDecoder().decode(Array<Album>.self, from: data.0)
    }

    func fetchPhotos(albumId: Int) async throws -> [Photo] {
        let url = URL(string: "https://jsonplaceholder.typicode.com/albums/\(albumId)/photos")!
        let data = try await session.btData(from: url)
        return try JSONDecoder().decode(Array<Photo>.self, from: data.0)
    }

    func fetchPhoto(url: URL) async throws -> Data {
        try await session.btData(from: url).0
    }
}
