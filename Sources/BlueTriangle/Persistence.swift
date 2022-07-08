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

    init(fileManager: FileManager = .default, file: File) {
        self.fileManager = fileManager
        self.file = file
    }

    func save<T: Encodable>(_ object: T) throws {
        let data = try JSONEncoder().encode(object)
        try fileManager.createDirectory(at: file.directory, withIntermediateDirectories: true)
        try data.write(to: file.url, options: .atomic)
    }

    func read<T: Decodable>() throws -> T? {
        guard let data = try readData() else {
            return nil
        }
        let object = try JSONDecoder().decode(T.self, from: data)
        return object
    }

    func readData() throws -> Data? {
        do {
            return try Data(contentsOf: file.url)
        } catch CocoaError.Code.fileReadNoSuchFile {
            return nil
        } catch {
            throw error
        }
    }

    func clear() throws {
        do {
            try fileManager.removeItem(at: file.url)
        } catch CocoaError.Code.fileNoSuchFile {
            return
        } catch {
            throw error
        }
    }
}

extension Persistence {
    static let crashReport = Self(fileManager: .default,
                                  file: try! File.makeCrashReport())
}

struct CrashReportPersistence {
    static let persistence: Persistence = .crashReport
    static let logger = BTLogger.live

    static func save(_ exception: NSException) {
        let report = CrashReport(exception: exception)
        do {
            try persistence.save(report)
        } catch {
            logger.error("Error saving \(report) to \(persistence.file.path): \(error.localizedDescription)")
        }
    }

    static func read() -> CrashReport? {
        do {
            return try persistence.read()
        } catch {
            logger.error("Error reading object at \(persistence.file.path): \(error.localizedDescription)")
            return nil
        }
    }

    static func clear() {
        do {
            try persistence.clear()
        } catch {
            logger.error("Error clearing data at \(persistence.file.path): \(error.localizedDescription)")
        }
    }
}
    }
}
