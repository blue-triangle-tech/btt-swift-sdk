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
    private let networkMonitor: NWPathMonitor
    private var cancellables = Set<AnyCancellable>()
    var send: ((Request) -> Void)?

    init(persistence: RequestCache) {
        self.persistence = persistence
        let networkMonitor = NWPathMonitor()
        self.networkMonitor = networkMonitor
    }

    convenience init?(file: File?, logger: Logging) {
        guard let file = file else {
            return nil
        }
        self.init(persistence: RequestCache(persistence: Persistence(file: file), logger: logger))
    }

    func configureSubscriptions(queue: DispatchQueue) {
        networkMonitor.publisher(queue: queue)
            .filter { $0.status == .satisfied }
            .sink { [weak self] path in
                self?.sendSaved()
            }.store(in: &cancellables)

        NotificationCenter.default.publisher(for: .willTerminate)
            .sink { [weak self] _ in
                self?.persistence.saveBuffer()
            }.store(in: &cancellables)
    }

    func store(request: Request) {
        persistence.save(request)
    }

    func sendSaved() {
        guard let send = send, let requests = persistence.read() else {
            return
        }

        requests.forEach { send($0) }
    }
}
