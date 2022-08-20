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
        do {
            try fileManager.createDirectory(at: file.directory, withIntermediateDirectories: true)
            try data.write(to: file.url, options: .atomic)
        } catch {
            throw PersistenceError.file(path: file.path, error: error)
        }
    }

    func append(_ data: Data) throws {
        if fileManager.fileExists(atPath: file.path) {
            do {
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
            } catch {
                throw PersistenceError.file(path: file.path, error: error)
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
            throw PersistenceError.file(path: file.path, error: error)
        }
    }

    func clear() throws {
        do {
            try fileManager.removeItem(at: file.url)
        } catch CocoaError.Code.fileNoSuchFile {
            return
        } catch {
            throw PersistenceError.file(path: file.path, error: error)
        }
    }
}

extension Persistence {
    func save<T: Encodable>(_ object: T, encodingWith encoder: JSONEncoder = .init()) throws {
        do {
            let data = try encoder.encode(object)
            try write(data)
        } catch {
            throw PersistenceError(underlyingError: error)
        }
    }

    func read<T: Decodable>(decodingWith decoder: JSONDecoder = .init()) throws -> T? {
        guard let data = try readData() else {
            return nil
        }
        do {
            let object = try decoder.decode(T.self, from: data)
            return object
        } catch {
            throw PersistenceError(underlyingError: error)
        }
    }
}
