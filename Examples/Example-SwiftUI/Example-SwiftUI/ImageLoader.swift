//
//  ImageLoader.swift
//
//  Created by Mathew Gacy on 11/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
import IdentifiedCollections
import Service
import SwiftUI
import UIKit

// MARK: - Models

enum ImageStatus {
    case loading
    case downloaded(UIImage)
    case error(Error)
}

struct ImageDownload: Identifiable {
    let id: URL
    let status: ImageStatus
}

// MARK: - ImageLoader

final class ImageLoader: ObservableObject {
    struct ImageResult: Identifiable {
        let id: URL
        let result: Result<UIImage, Error>
    }

    @Published @MainActor private(set) var images: IdentifiedArrayOf<ImageDownload> = []
    private let networking: (URL) async throws -> ResponseValue

    init(
        networking: @escaping (URL) async throws -> ResponseValue
    ) {
        self.networking = networking
    }

    func fetch(urls: [URL]) async {
        await withTaskGroup(of: ImageResult.self, returning: Void.self) { group in
            urls.forEach { url in
                group.addTask {
                    await self.fetchImage(url: url)
                }
            }

            await updateImages(
                IdentifiedArrayOf(
                    uniqueElements: urls.map { ImageDownload(id: $0, status: .loading) }))

            for await imageResult in group {
                switch imageResult.result {
                case .success(let image):
                    await updateStatus(imageResult.id, status: .downloaded(image))
                case .failure(let error):
                    await updateStatus(imageResult.id, status: .error(error))
                }
            }
        }
    }
}

private extension ImageLoader {
    func fetchImage(url: URL) async -> ImageResult {
        do {
            let responseValue = try await networking(url)
                .validate()

            guard let image = UIImage(data: responseValue.data) else {
                throw "Cannot parse image"
            }

            return ImageResult(id: url, result: .success(image))
        } catch {
            return ImageResult(id: url, result: .failure(error))
        }
    }

    @MainActor
    func updateImages(_ newImages: IdentifiedArrayOf<ImageDownload>) {
        withAnimation {
            images = newImages
        }
    }

    @MainActor
    func updateStatus(_ url: URL, status: ImageStatus) {
        withAnimation {
            images[id: url] = ImageDownload(id: url, status: status)
        }
    }
}

extension ImageLoader {
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
