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

    func write(_ data: Data) throws {
        try fileManager.createDirectory(at: file.directory, withIntermediateDirectories: true)
        try data.write(to: file.url, options: .atomic)
    }

    func append(_ data: Data) throws {
        if fileManager.fileExists(atPath: file.path) {
            let fileHandle = try FileHandle(forUpdating: file.url)

            if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, watchOS 6.2, *) {
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: data)
                try fileHandle.close()
            } else {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try write(data)
        }
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
    func save<T: Encodable>(_ object: T, encodingWith encoder: JSONEncoder = .init()) throws {
        let data = try encoder.encode(object)
        try write(data)
    }

    func read<T: Decodable>(decodingWith decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = try readData() else {
            return nil
        }
        let object = try decoder.decode(T.self, from: data)
        return object
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
