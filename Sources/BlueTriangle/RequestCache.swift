//
//  RequestCache.swift
//
//  Created by Mathew Gacy on 6/26/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct RequestCache {
    enum Constants {
        static let lineBreak = Data([10])
    }

    private let persistence: Persistence
    private let maxSize: Int
    private var buffer: Data = .init()

    init(persistence: Persistence, maxSize: Int = 1024 * 1024) {
        self.persistence = persistence
        self.maxSize = maxSize
    }

    mutating func save(_ request: Request) throws {
        do {
            let data = try JSONEncoder().encode(request) + Constants.lineBreak
            buffer.append(data)
        } catch {
            throw PersistenceError(underlyingError: error)
        }

        if buffer.count > maxSize {
            try saveBuffer()
        }
    }

    mutating func saveBuffer() throws {
        defer {
            clearBuffer()
        }

        try persistence.append(buffer)
    }

    func read() throws -> [Request]? {
        let data: Data
        let decoder = JSONDecoder()
        do {
            if let disk = try persistence.readData() {
                data = disk + Constants.lineBreak + buffer
            } else {
                data = buffer
            }

            return try data
                .split(separator: Constants.lineBreak[0])
                .map { try decoder.decode(Request.self, from: $0) }
        } catch {
            throw PersistenceError(underlyingError: error)
        }
    }

    mutating func clear() throws {
        clearBuffer()
        try persistence.clear()
    }

    private mutating func clearBuffer() {
        buffer = Data()
    }
}
