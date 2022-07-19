//
//  RequestFailureHandler.swift
//
//  Created by Mathew Gacy on 6/12/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Combine
import Foundation
import Network

final class RequestFailureHandler: RequestFailureHandling {
    private var persistence: RequestCache
    private let logger: Logging
    private let networkMonitor: NWPathMonitor
    private var cancellables = Set<AnyCancellable>()
    var send: ((Request) -> Void)?

    init(persistence: RequestCache, logger: Logging) {
        self.persistence = persistence
        self.logger = logger
        self.networkMonitor = NWPathMonitor()
    }

    convenience init?(file: File?, logger: Logging) {
        guard let file = file else {
            return nil
        }
        self.init(
            persistence: RequestCache(persistence: Persistence(file: file)),
            logger: logger)
    }

    func configureSubscriptions(queue: DispatchQueue) {
        networkMonitor.publisher(queue: queue)
            .filter { $0.status == .satisfied }
            .sink { [weak self] _ in
                self?.sendSaved()
            }.store(in: &cancellables)

        NotificationCenter.default.publisher(for: .willTerminate)
            .sink { [weak self] _ in
                do {
                    try self?.persistence.saveBuffer()
                } catch {
                    self?.log(error)
                }
            }.store(in: &cancellables)
    }

    func store(request: Request) {
        do {
            try persistence.save(request)
        } catch {
            log(error)
        }
    }

    func sendSaved() {
        do {
            guard let send = send, let requests = try persistence.read() else {
                return
            }

            logger.info("Resending \(requests.count) requests.")
            requests.forEach { send($0) }

            try persistence.clear()
        } catch {
            log(error)
        }
    }

    private func log(_ error: Error) {
        let message = (error as? PersistenceError)?.localizedDescription ?? error.localizedDescription
        logger.error(message)
    }
}
