//
//  PlaceholderServiceProtocol.swift
//  Example-UIKit
//
//  Created by Mathew Gacy on 8/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

protocol PlaceholderServiceProtocol {
    func fetchAlbums() async throws -> [Album]
    func fetchPhotos(albumId: Int) async throws -> [Photo]
    func fetchPhoto(url: URL) async throws -> Data
}
