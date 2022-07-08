//
//  CrashReportPersistence.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

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
