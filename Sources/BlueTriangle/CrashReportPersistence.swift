//
//  CrashReportPersistence.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CrashReportPersistence {
    private static let logger = BTLogger.live

    private static var persistence: Persistence? {
        guard let file = File.crashReport else {
            logger.error("Failed to get URL for ")
            return nil
        }
        return Persistence(fileManager: .default, file: file)
    }

    private static var path: String {
        persistence?.file.path ?? "MISSING"
    }

    static func save(_ exception: NSException) {
        let report = CrashReport(exception: exception)
        do {
            try persistence?.save(report)
        } catch {
            logger.error("Error saving \(report) to \(path): \(error.localizedDescription)")
        }
    }

    static func read() -> CrashReport? {
        do {
            return try persistence?.read()
        } catch {
            logger.error("Error reading object at \(path): \(error.localizedDescription)")
            return nil
        }
    }

    static func clear() {
        do {
            try persistence?.clear()
        } catch {
            logger.error("Error clearing data at \(path): \(error.localizedDescription)")
        }
    }
}
