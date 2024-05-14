//
//  LaunchTimeMonitor.swift
//  
//
//  Created by Ashok Singh on 06/05/24.
//

import Foundation
import Combine
import AppEventLogger

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
    internal var  launchEventPubliser = CurrentValueSubject<LaunchEvent?, Never>(nil)
      
    init() {
        self.restoreNotificationLogs()
        self.registerNotifications()
    }
    
    private func restoreNotificationLogs(){
        let notifications = AppNotificationLogger.getNotifications()
        notifications.forEach { notification in
            if let notificationLog = notification as? NotificationLog {
                self.processNonification(notificationLog.notification, date: notificationLog.time)
            }
        }
        AppNotificationLogger.removeObserver()
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
                self.launchEventPubliser.send(LaunchEvent.Cold(startTime, duration))
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
                self.launchEventPubliser.send(LaunchEvent.Hot(startTime, duration))
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
    
    private func processNonification(_ notification: Notification, date : Date) {
        if notification.name == UIApplication.didFinishLaunchingNotification {
            self.systemEventLog.append(SystemEvent.didFinishLaunch(date))
        } else if notification.name == UIApplication.willEnterForegroundNotification {
            self.systemEventLog.append(SystemEvent.didEnterForeground(date))
        }else if notification.name == UIApplication.didBecomeActiveNotification {
            self.systemEventLog.append(SystemEvent.didBecomeActive(date))
            self.notifyLaunchTime()
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: nil) { notification in
            self.processNonification(notification, date: Date())
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { notification in
            self.processNonification(notification, date: Date())
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { notification in
            self.processNonification(notification, date: Date())
        }
        logger?.info("Launch time monitor started listining to system event")
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
