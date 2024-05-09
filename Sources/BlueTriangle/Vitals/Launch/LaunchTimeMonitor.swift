//
//  LaunchTimeMonitor.swift
//  
//
//  Created by Ashok Singh on 06/05/24.
//

import Foundation
import Combine

#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

enum LaunchEvent{
    case Cold(Date, TimeInterval)
    case Hot(Date, TimeInterval)
}

enum SystemEvent {
    case didFinishLaunch(Date)
    case didEnterForeground(Date)
    case didBecomeActive(Date)
}

public class LaunchTimeMonitor : ObservableObject{
    
    private var logger: Logging?
    private var  systemEventLog = [SystemEvent]()
    internal var launchEvents =  MultiValueSubject<LaunchEvent>()
      
    init() {
        self.registerNotifications()
    }
    
    func setUpLogger(_ logger : Logging?){
        self.logger = logger
    }
    
    private func notifyCold(){
        
        let firstEvent = self.systemEventLog.first
        let lastEvent = self.systemEventLog.last
        
        switch firstEvent {
        case .didFinishLaunch(let startTime):
            switch lastEvent {
            case .didBecomeActive(let endTime):
                let processTime = processStartTime()
                let duration = endTime.timeIntervalSince1970 - processTime
                self.launchEvents.send(LaunchEvent.Cold(startTime, duration))
                self.logger?.info("Notify cold launch at \(startTime)")
            default:
                self.logger?.error("Somthing went wrong to notify cold launch")
            }
        default:
            self.logger?.error("Somthing went wrong to notify cold launch")
        }
    }
    
    private func notifyHot(){
        
        let firstEvent = self.systemEventLog.first
        let lastEvent = self.systemEventLog.last
        
        switch firstEvent {
        case .didEnterForeground(let startTime):
            switch lastEvent {
            case .didBecomeActive(let endTime):
                let duration = endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970
                self.launchEvents.send(LaunchEvent.Hot(startTime, duration))
                self.logger?.info("Notify hot launch at \(startTime)")
            default:
                self.logger?.error("Somthing went wrong to notify hot launch")
            }
        default:
            self.logger?.error("Somthing went wrong to notify hot launch")
        }
    }
    
    private func reset(){
        self.systemEventLog.removeAll()
    }
}

extension LaunchTimeMonitor {
    
    private func registerNotifications() {
         NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) { notification in
            if notification.name == UIApplication.didFinishLaunchingNotification {
                self.systemEventLog.append(SystemEvent.didFinishLaunch(Date()))
            } else if notification.name == UIApplication.willEnterForegroundNotification {
                self.systemEventLog.append(SystemEvent.didEnterForeground(Date()))
            }else if notification.name == UIApplication.didBecomeActiveNotification {
                self.systemEventLog.append(SystemEvent.didBecomeActive(Date()))
                self.notifyLaunchTime()
             }
        }
        
        logger?.info("Setup to notify launch event")
    }

    private func notifyLaunchTime(){
        let firstEvent = self.systemEventLog.first
        let lastEvent = self.systemEventLog.last
     
        switch firstEvent {
        case .didFinishLaunch:
            switch lastEvent {
            case .didBecomeActive:
                notifyCold()
            default:
                notifyHot()
            }
        default:
            notifyHot()
        }
        reset()
    }
    
    private func processStartTime() -> Double {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        let start_time = kinfo.kp_proc.p_starttime
        let processTime = Double(start_time.tv_sec) + Double(start_time.tv_usec) / 1e6
        return processTime
    }
}


public class MultiValueSubject<Output>: Publisher {
    public typealias Failure = Never
    private var values: [Output] = []
    private var subscribers: [AnySubscriber<Output, Never>] = []

    public init() {}

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = Subscription(subscriber: AnySubscriber(subscriber), values: values)
        subscribers.append(AnySubscriber(subscriber))
        subscriber.receive(subscription: subscription)
    }

    public func send(_ value: Output) {
        values.append(value)
        subscribers.forEach { _ = $0.receive(value) }
    }

    private class Subscription: Combine.Subscription {
        private var subscriber: AnySubscriber<Output, Never>?
        private var values: [Output]

        init(subscriber: AnySubscriber<Output, Never>, values: [Output]) {
            self.subscriber = subscriber
            self.values = values
            values.forEach{_ = subscriber.receive($0)}
        }

        func request(_ demand: Subscribers.Demand) {}

        func cancel() {
            subscriber = nil
        }
    }
}
