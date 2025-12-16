//
//  NetworkClientMock.swift
//
//  Created by Mathew Gacy on 1/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
@testable import BlueTriangle
import Foundation
import UIKit

// swiftlint:disable identifier_name
public func compose <A, B, C>(_ f: @escaping (A) -> B, _ g: @escaping (B) -> C) -> (A) -> C {
    return { x in g(f(x)) }
}

// MARK: - Create Data for Responses

enum JSONFactory {
    private static func makeCollection(count: Int, from: (Int) -> String) -> String {
        "[" + Array(1...count)
            .map(from)
            .joined(separator: ",")
            .appending("]")
    }

    static func makeAlbum(id: Int) -> String {
        """
        {
            "userId": 1,
            "id": \(id),
            "title": "quidem molestiae enim"
        }
        """
    }

    static func makePhoto(id: Int) -> String {
        """
        {
            "albumId": 1,
            "id": \(id),
            "title": "accusamus beatae ad facilis cum similique qui sunt",
            "url": "https://example.com/600/\(id)",
            "thumbnailUrl": "https://example.com/150/\(id)"
        }
        """
    }

    static func makeAlbums(count: Int) -> String {
        makeCollection(count: count, from: makeAlbum(id:))
    }

    static func makePhotos(count: Int) -> String {
        makeCollection(count: count, from: makePhoto(id:))
    }
}

extension JSONFactory {
    static func data(from string: String) -> Data {
        string.data(using: .utf8) ?? .init()
    }
}

// MARK: - Determine Delay for Responses

struct DelayGenerator {
    enum Strategy {
        typealias RandomConfig = (mean: TimeInterval, variation: TimeInterval)
        case random(RandomConfig)
        case deterministic([TimeInterval])
    }

    private let strategy: Strategy

    init(strategy: Strategy) {
        self.strategy = strategy
    }

    func delay(for id: Int) -> TimeInterval {
        switch strategy {
        case .random(let config):
            let range = config.mean - (0.5 * config.variation) ... config.mean + (0.5 * config.variation)
            return TimeInterval.random(in: range)
        case .deterministic(let array):
            return array[id - 1]
        }
    }
}

// MARK: - Make Responses

struct MockRequest<ID: Sendable> : Sendable{
    let builder: @Sendable (ID) -> Data
    let translator: @Sendable (ID) -> Int
    let delayGenerator: DelayGenerator

    func fetch(_ value: ID) async throws -> Data {
        let delay = delayGenerator.delay(for: translator(value))
        let task = Task.delayed(byTimeInterval: delay, priority: .userInitiated) {
            builder(value)
        }
        return try await task.value
    }
}

extension MockRequest where ID == Int {
    init(builder: @Sendable @escaping (ID) -> Data, delayStrategy: DelayGenerator.Strategy) {
        self.builder = builder
        self.translator = { $0 }
        self.delayGenerator = .init(strategy: delayStrategy)
    }
}

extension MockRequest where ID == URL {
    static func makePhotoRequest(delayStrategy: DelayGenerator.Strategy, imageSize: CGSize) -> MockRequest<URL> {
        MockRequest(builder: { url in
                        let color = UIColor.sampleColors.randomElement() ?? .brown
                        return color.pngData(imageSize)
                     },
                     translator: { Int($0.lastPathComponent) ?? 1 },
                     delayGenerator: .init(strategy: delayStrategy))
    }
}

// MARK: - Network Client

struct NetworkClientMock {
    var albumCollectionSize: Int = 10
    var photoCollectionSize: Int = 10

    var albumCollectionRequest: MockRequest<Int>
    var albumPhotosRequest: MockRequest<Int>
    var photoRequest: MockRequest<URL>

    func fetchAlbums() async throws -> [Album] {
        let data = try await albumCollectionRequest.fetch(albumCollectionSize)
        return try JSONDecoder().decode(Array<Album>.self, from: data)
    }

    func fetchPhotos(albumId: Int) async throws -> [Photo] {
        let data = try await albumPhotosRequest.fetch(photoCollectionSize)
        return try JSONDecoder().decode(Array<Photo>.self, from: data)
    }

    func fetchPhoto(url: URL) async throws -> Data {
        try await photoRequest.fetch(url)
    }
}

extension NetworkClientMock {
}

#endif
