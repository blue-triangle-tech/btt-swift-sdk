//
//  UserLocation.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

enum UserLocation: FileLocation {
    public typealias PathComponent = String

    case document(PathComponent)
    case cache(PathComponent)
    case temp(PathComponent)

    var containerURL: URL? {
        baseURL?.appendingPathComponent(pathComponent)
    }

    // MARK: - Private

    private var fileManager: FileManager {
        .default
    }

    private var baseURL: URL? {
        switch self {
        case .document:
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case .cache:
            var baseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            #if os(macOS)
            if let appName = Bundle.main.appName {
                baseURL = baseURL?.appendingPathComponent(appName)
            }
            #endif
            return baseURL
        case .temp:
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
    }

    private var pathComponent: PathComponent {
        switch self {
        case .document(let component): return component
        case .cache(let component): return component
        case .temp(let component): return component
        }
    }
}
