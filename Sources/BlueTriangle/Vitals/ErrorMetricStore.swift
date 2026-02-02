//
//  ErrorMetricStore.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/01/26.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

public actor ErrorMetricStore {
    
    private var anrs: [UUID: ErrorMetric] = [:]
    private var memoryWarnings: [UUID: ErrorMetric] = [:]
    private var errors: [UUID: ErrorMetric] = [:]
    
    // MARK: - Add
    
    func addAnrError(id: UUID, message: String) {
        if let current = anrs[id] {
            anrs[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: 1
            )
        } else {
            anrs[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: 1
            )
        }
    }
    
    func addMemoryWarning(id: UUID, message: String) {
        if let current = memoryWarnings[id] {
            memoryWarnings[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: 1
            )
        } else {
            memoryWarnings[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: 1
            )
        }
    }
    
    func addError(id: UUID, message: String, line: UInt = 1) {
        if let current = errors[id] {
            errors[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: line
            )
        } else {
            errors[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: line
            )
        }
    }
    
    // MARK: - Flush (get + remove)
    func flushAnrError(id: UUID) -> ErrorMetric? {
        anrs.removeValue(forKey: id)
    }
    
    func flushMemoryWarning(id: UUID) -> ErrorMetric? {
        memoryWarnings.removeValue(forKey: id)
    }
    
    func flushError(id: UUID) -> ErrorMetric? {
        errors.removeValue(forKey: id)
    }
}

struct ErrorMetric {
    let message: String
    let eCount: Int
    let line: UInt
    let time = Date().timeIntervalSince1970
}
