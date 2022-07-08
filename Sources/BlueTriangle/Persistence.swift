//
//  Persistence.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct Persistence {
    private let fileManager: FileManager

    let file: File

    private let logger: Logging

    init(fileManager: FileManager, file: File, logger: Logging) {
        self.fileManager = fileManager
        self.file = file
        self.logger = logger
    }

    func save<T: Encodable>(_ object: T) {
        if fileManager.fileExists(atPath: file.path) {
            logger.info("Deleting existing file at \(file.path)")
        }

        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: file.url)
        } catch {
            logger.error("Error saving \(object) to \(file.path): \(error.localizedDescription)")
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
            logger.error("Error decoding object at \(file.path): \(error.localizedDescription)")
            return nil
        }
    }

    func readData() -> Data? {
        guard fileManager.fileExists(atPath: file.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: file.url)
            return data
        } catch {
            logger.error("Error reading data at \(file.path): \(error.localizedDescription)")
            return nil
        }
    }

    func clear() {
        guard fileManager.fileExists(atPath: file.path) else {
            return
        }
        do {
            try fileManager.removeItem(at: file.url)
        } catch {
            logger.error("\(error)")
        }
    }
}

extension Persistence {
    static let crashReport = Self(fileManager: .default,
                                  file: try! File.makeCrashReport(),
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
