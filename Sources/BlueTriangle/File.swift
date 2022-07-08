//
//  File.swift
//
//  Created by Mathew Gacy on 7/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct File {
    enum FileError: Error {
        case missingURL
    }

    let directory: URL
    let name: String

    var url: URL {
        directory.appendingPathComponent(name)
    }

    var path: String {
        url.path
    }

    init(directory: URL, name: String) {
        self.directory = directory
        self.name = name
    }

    init(fileLocation: FileLocation, name: String) throws {
        guard let containerURL = fileLocation.containerURL else {
            throw FileError.missingURL
        }
        self.directory = containerURL
        self.name = name
    }
}

extension File {
    static func makeCrashReport() throws -> Self {
        try Self(fileLocation: UserLocation.cache(Constants.persistenceDirectory), name: "crash_report")
    }

    static func makeRequests() throws -> Self {
        try Self(fileLocation: UserLocation.cache(Constants.persistenceDirectory), name: "requests")
    }
}
