//
//  ImageLoader.swift
//
//  Created by Mathew Gacy on 11/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import BlueTriangle
import Foundation
import IdentifiedCollections
import Service
import SwiftUI
import UIKit

// MARK: - Model

enum ImageStatus: CustomStringConvertible {
    case loading(Task<ImageLoader.ImageResult, Never>)
    case downloaded(Result<UIImage, Error>)

    var description: String {
        switch self {
        case .loading:
           return "ImageStatus.loading"
        case .downloaded(.success):
            return "ImageStatus.downloaded - success"
        case .downloaded(.failure(let error)):
            return "ImageStatus.downloaded - failure: \(error.localizedDescription)"
        }
    }
}

// MARK: - ImageLoader

actor ImageLoader {
    struct ImageResult {
        let url: URL
        let result: Result<UIImage, Error>
    }

    private(set) var images: [URL: ImageStatus] = [:]
    private let networking: (URL) async throws -> ResponseValue

    init(
        networking: @escaping (URL) async throws -> ResponseValue
    ) {
        self.networking = networking
    }

    func fetch(urls: [URL]) async throws {
        await withTaskGroup(of: ImageResult.self, returning: Void.self) { group in
            var imagesUpdate: [URL: ImageStatus] = [:]
            urls.forEach { url in
                let task = downloadTask(url: url)
                imagesUpdate[url] = .loading(task)

                group.addTask {
                    return await task.value
                }
            }

            updateImages(imagesUpdate)

            for await imageResult in group {
                updateStatus(imageResult.url, result: imageResult.result)
            }
        }
    }
}

private extension ImageLoader {
    func updateImages(_ newImages: [URL: ImageStatus]) {
        images = newImages
    }

    func updateStatus(_ url: URL, result: Result<UIImage, Error>) {
        images[url] = .downloaded(result)
    }

    func downloadTask(url: URL, priority: TaskPriority? = nil) -> Task<ImageResult, Never> {
        Task(priority: priority) {
            await fetchImage(url: url)
        }
    }

    func fetchImage(url: URL) async -> ImageResult {
        do {
            let responseValue = try await networking(url)
                .validate()

            guard let image = UIImage(data: responseValue.data) else {
                throw "Cannot parse image"
            }

            return ImageResult(url: url, result: .success(image))
        } catch {
            return ImageResult(url: url, result: .failure(error))
        }
    }
}

extension ImageLoader {
    static var live: ImageLoader {
        let configuration = URLSessionConfiguration.default
        let delegate = NetworkCaptureSessionDelegate()

        let session = URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil)

        return ImageLoader(
            networking: { url in
                try ResponseValue(try await session.data(from: url))
            })
    }

    static var mock: ImageLoader {
        ImageLoader(networking: { url in
            ResponseValue(
                data: UIColor.random().image().pngData() ?? Data(),
                httpResponse: HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil)!
            )
        })
    }
}
