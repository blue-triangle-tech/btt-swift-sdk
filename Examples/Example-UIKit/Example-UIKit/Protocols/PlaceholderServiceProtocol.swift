//
//  PlaceholderServiceProtocol.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//

import Foundation

protocol PlaceholderServiceProtocol {
    func fetchAlbums() async throws -> [Album]
    func fetchPhotos(albumId: Int) async throws -> [Photo]
    func fetchPhoto(url: URL) async throws -> Data
}
