//
//  AppEventObserver.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit.UIApplication

let launchNotification = UIApplication.didFinishLaunchingNotification
let activeNotification = UIApplication.didBecomeActiveNotification
let backgroundNotification = UIApplication.didEnterBackgroundNotification
let terminateNotification = UIApplication.willTerminateNotification
#elseif os(watchOS)
import WatchKit.WKExtension

@available(watchOS 7.0, *)
let launchNotification = WKExtension.applicationDidFinishLaunchingNotification
@available(watchOS 7.0, *)
let activeNotification = WKExtension.applicationDidBecomeActiveNotification
@available(watchOS 7.0, *)
let backgroundNotification = WKExtension.applicationDidEnterBackgroundNotification
#elseif os(macOS)
import AppKit.NSApplication

let launchNotification = NSApplication.didFinishLaunchingNotification
let activeNotification = NSApplication.didBecomeActiveNotification
let backgroundNotification = NSApplication.willResignActiveNotification
let terminateNotification = NSApplication.willTerminateNotification
#endif

class AppEventObserver {
    typealias EventHandler = () -> Void

    let onLaunch: EventHandler?
    let onActive: EventHandler?
    let onBackground: EventHandler?
    let onTermination: EventHandler?

    init(
        onLaunch: EventHandler? = nil,
        onActive: EventHandler? = nil,
        onBackground: EventHandler? = nil,
        onTermination: EventHandler? = nil
    ) {
        self.onLaunch = onLaunch
        self.onActive = onActive
        self.onBackground = onBackground
        self.onTermination = onTermination
    }

    func configureNotifications() {
        let center = NotificationCenter.default

        #if os(watchOS)
        guard #available(watchOS 7.0, *) else {
            return
        }
        #endif
        center.addObserver(self, selector: #selector(onDidFinishLaunching(_:)), name: launchNotification, object: nil)
        center.addObserver(self, selector: #selector(onDidBecomeActive(_:)), name: activeNotification, object: nil)
        center.addObserver(self, selector: #selector(onDidEnterBackground), name: backgroundNotification, object: nil)

        #if !os(watchOS)
        center.addObserver(self, selector: #selector(onWillTerminate(_:)), name: terminateNotification, object: nil)
        #endif
    }

    @objc
    func onDidFinishLaunching(_ notification: NSNotification) {
        onLaunch?()
    }

    @objc
    func onDidBecomeActive(_ notification: NSNotification) {
        onActive?()
    }

    @objc
    func onDidEnterBackground(_ notification: NSNotification) {
        onBackground?()
    }

    @objc
    func onWillTerminate(_ notification: NSNotification) {
        onTermination?()
    }
}
