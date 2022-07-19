//
//  NWPathMonitor+Combine.swift
//
//  Created by Mathew Gacy on 6/12/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Combine
import Network

extension NWPathMonitor {
    class NetworkStatusSubscription<Target: Subscriber>: Subscription where Target.Input == NWPath {
        private let monitor: NWPathMonitor
        private let queue: DispatchQueue
        private var target: Target?

        init(monitor: NWPathMonitor, queue: DispatchQueue, target: Target) {
            self.monitor = monitor
            self.queue = queue
            self.target = target
        }

        func request(_ demand: Subscribers.Demand) {
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else {
                    return
                }

                _ = self.target?.receive(path)
            }

            monitor.start(queue: queue)
        }

        func cancel() {
            monitor.pathUpdateHandler = nil
            monitor.cancel()
            target = nil
        }
    }

    struct NetworkStatusPublisher: Publisher {
        typealias Output = NWPath
        typealias Failure = Never

        private let monitor: NWPathMonitor
        private let queue: DispatchQueue

        init(monitor: NWPathMonitor, queue: DispatchQueue) {
            self.monitor = monitor
            self.queue = queue
        }

        func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            let subscription = NetworkStatusSubscription(
                monitor: monitor,
                queue: queue,
                target: subscriber)

            subscriber.receive(subscription: subscription)
        }
    }

    func publisher(queue: DispatchQueue) -> NWPathMonitor.NetworkStatusPublisher {
        NetworkStatusPublisher(monitor: self, queue: queue)
    }
}
