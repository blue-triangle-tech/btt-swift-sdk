//
//  RequestPersistence.swift
//
//  Created by Mathew Gacy on 6/26/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct RequestPersistence {
    enum Constants {
        static let lineBreak = Data([10])
    }

    private let persistence: Persistence
    private let logger: Logging
    private let maxSize: Int
    private var buffer: Data = .init()

    init(persistence: Persistence, logger: Logging, maxSize: Int = 1024 * 1024) {
        self.persistence = persistence
        self.logger = logger
        self.maxSize = maxSize
    }

    mutating func save(_ request: Request) {
        do {
            let data = try JSONEncoder().encode(request) + Constants.lineBreak
            buffer.append(data)
        } catch {
            let path = persistence.file.path
            logger.error("Error saving \(request) to \(path): \(error.localizedDescription)")
        }

        if buffer.count > maxSize {
            saveBuffer()
        }
    }
    
    mutating func saveBuffer() {
        defer {
            clearBuffer()
        }
        do {
            try persistence.append(buffer)
        } catch {
            let path = persistence.file.path
            logger.error("Error appending buffer to \(path): \(error.localizedDescription)")
        }
    }

    func read() throws -> [Request]? {
        let data: Data
        if let disk = try persistence.readData() {
            data = disk + Constants.lineBreak + buffer
        } else {
            data = buffer
        }

        let decoder = JSONDecoder()
        return try data
            .split(separator: Constants.lineBreak[0])
            .map { try decoder.decode(Request.self, from: $0) }
    }

    mutating func clear() throws {
        clearBuffer()
        do {
        try persistence.clear()
        } catch {
            let path = persistence.file.path
            logger.error("Error removing file at \(path): \(error.localizedDescription)")
        }
    }

    private mutating func clearBuffer() {
        buffer = Data()
    }
}
