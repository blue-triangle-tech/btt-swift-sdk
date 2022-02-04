//
//  Persistence.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

protocol FileLocation {
    var containerURL: URL? { get }
}

enum UserLocation: FileLocation {
    public typealias PathComponent = String

    case document(PathComponent)
    case cache(PathComponent)
    case temp(PathComponent)

    var containerURL: URL? {
        return baseURL?.appendingPathComponent(pathComponent)
    }

    // MARK: - Private

    private var fileManager: FileManager {
        return .default
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

struct Persistence {
    private let fileManager: FileManager

    private let fileLocation: FileLocation

    private let logger: Logging

    private var containerURL: URL? {
        return fileLocation.containerURL
    }

    init(fileManager: FileManager, fileLocation: FileLocation, logger: Logging) {
        self.fileManager = fileManager
        self.fileLocation = fileLocation
        self.logger = logger
    }

    func save<T: Encodable>(_ object: T) {
        guard let containerURL = containerURL else {
            return
        }
        if fileManager.fileExists(atPath: containerURL.path) {
            logger.info("Deleting existing file at \(containerURL.path)")
        }

        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: containerURL)
        } catch {
            logger.error("Error saving \(object) to \(containerURL.path): \(error.localizedDescription)")
        }
    }

    func read<T: Decodable>() -> T? {
        guard let data = readData() else {
            return nil
        }
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            logger.error("Error decoding object at \(containerURL?.path ?? ""): \(error.localizedDescription)")
            return nil
        }
    }

    func readData() -> Data? {
        guard let containerURL = containerURL, fileManager.fileExists(atPath: containerURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: containerURL)
            return data
        } catch {
            logger.error("Error reading data at \(containerURL.path): \(error.localizedDescription)")
            return nil
        }
    }

    func clear() {
        guard let containerURL = containerURL, fileManager.fileExists(atPath: containerURL.path) else {
            return
        }
        do {
            try fileManager.removeItem(at: containerURL)
        } catch {
            logger.error("\(error)")
        }
    }
}

extension Persistence {
    static let crashReport = Self(fileManager: .default,
                                  fileLocation: UserLocation.cache(Constants.crashReportFilename),
                                  logger: BTLogger.live)
}

struct CrashReportPersistence {
    static let persistence: Persistence = .crashReport

    static func save(_ exception: NSException) {
        persistence.save(CrashReport(exception: exception))
    }

    static func read() -> CrashReport? {
        persistence.read()
    }

    static func clear() {
        persistence.clear()
    }
}
