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

// MARK: - EnvironmentValues

struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue = ImageLoader.shared
}

extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self ] = newValue}
    }
}

// MARK: - ImageLoader

final class ImageLoader: ObservableObject {
    struct ImageResult: Identifiable {
        let id: URL
        let result: Result<UIImage, Error>
    }

    public static let shared: ImageLoader = {
        ImageLoader()
    }()

    private var networking: (URL) async throws -> ResponseValue = { url in
        try ResponseValue(try await URLSession.shared.data(from: url))
    }

    @Published @MainActor private(set) var images: IdentifiedArrayOf<ImageDownload> = []

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
