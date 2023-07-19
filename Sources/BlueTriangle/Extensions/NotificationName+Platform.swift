//
//  NotificationName+Platform.swift
//
//  Created by Mathew Gacy on 7/2/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit.UIApplication
#elseif os(watchOS)
import WatchKit.WKExtension
#elseif os(macOS)
import AppKit.NSApplication
#endif

extension Notification.Name {
    @available(watchOS 7.0, *)
    static var finishedLaunching: Self {
        #if os(iOS) || os(tvOS)
        return UIApplication.didFinishLaunchingNotification
        #elseif os(watchOS)
        return WKExtension.applicationDidFinishLaunchingNotification
        #elseif os(macOS)
        return NSApplication.didFinishLaunchingNotification
        #endif
    }

    @available(watchOS 7.0, *)
    static var becameActive: Self {
        #if os(iOS) || os(tvOS)
        return UIApplication.didBecomeActiveNotification
        #elseif os(watchOS)
        return WKExtension.applicationDidBecomeActiveNotification
        #elseif os(macOS)
        return NSApplication.didBecomeActiveNotification
        #endif
    }

    @available(watchOS 7.0, *)
    static var enteredBackground: Self {
        #if os(iOS) || os(tvOS)
        return UIApplication.didEnterBackgroundNotification
        #elseif os(watchOS)
        return WKExtension.applicationDidEnterBackgroundNotification
        #elseif os(macOS)
        return NSApplication.willResignActiveNotification
        #endif
    }
    
    @available(watchOS 7.0, *)
    static var willTerminate: Self {
        #if os(iOS) || os(tvOS)
        return UIApplication.willTerminateNotification
        #elseif os(macOS)
        return NSApplication.willTerminateNotification
        #elseif os(watchOS)
            return WKExtension.applicationDidEnterBackgroundNotification
        #endif
    }
}
