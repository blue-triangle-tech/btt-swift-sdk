//
//  Uploader.swift
//
//  Created by Mathew Gacy on 10/25/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

protocol Uploading {
    func send(request: Request)
}

typealias Networking = (Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError>

class Uploader: Uploading {

    private let lock = NSLock()

    private let queue = DispatchQueue(label: "com.bluetriangle.uploader",
                                      qos: .userInitiated,
                                      autoreleaseFrequency: .workItem)

    private let log: (String) -> Void

    private let networking: Networking

    private var subscriptions = [UUID: AnyCancellable]()

     var subscriptionCount: Int {
         lock.sync { subscriptions.count }
     }

    init(log: @escaping (String) -> Void, networking: @escaping Networking) {
        self.log = log
        self.networking = networking
    }

    func send(request: Request) {
        let id = UUID()
        let publisher = networking(request)
            .retry(retries: 3, initialDelay: 10.0, delayMultiplier: 1.0, shouldRetry: nil, scheduler: queue)
            .subscribe(on: queue)
            .sink(
                receiveCompletion: { [weak self] completion in
                     if case .failure(let error) = completion {
                         self?.log(error.localizedDescription)
                     }
                    self?.removeSubscription(id: id)
                },
                receiveValue: { [weak self] value in
                    self?.log("\(value)")
                }
            )

        addSubscription(publisher, id: id)
    }

    private func addSubscription(_ cancellable: AnyCancellable, id: UUID) {
        lock.sync { subscriptions[id] = cancellable }
    }

    private func removeSubscription(id: UUID) {
        lock.sync { subscriptions[id] = nil }
    }
}

