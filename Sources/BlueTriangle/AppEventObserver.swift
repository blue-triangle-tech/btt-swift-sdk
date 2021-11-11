//
//  AppEventObserver.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

import Foundation
#if os(iOS) || os(tvOS)
import UIKit.UIApplication
let LaunchNotification = UIApplication.didFinishLaunchingNotification
let ActiveNotification = UIApplication.didBecomeActiveNotification
let BackgroundNotification = UIApplication.didEnterBackgroundNotification
let TerminateNotification = UIApplication.willTerminateNotification
#elseif os(watchOS)
import WatchKit.WKExtension
@available(watchOS 7.0, *)
let LaunchNotification = WKExtension.applicationDidFinishLaunchingNotification
@available(watchOS 7.0, *)
let ActiveNotification = WKExtension.applicationDidBecomeActiveNotification
@available(watchOS 7.0, *)
let BackgroundNotification = WKExtension.applicationDidEnterBackgroundNotification
#elseif os(macOS)
import AppKit.NSApplication
let LaunchNotification = NSApplication.didFinishLaunchingNotification
let ActiveNotification = NSApplication.didBecomeActiveNotification
let BackgroundNotification = NSApplication.willResignActiveNotification
let TerminateNotification = NSApplication.willTerminateNotification
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
        center.addObserver(self, selector: #selector(onDidFinishLaunching(_:)), name: LaunchNotification, object: nil)
        center.addObserver(self, selector: #selector(onDidBecomeActive(_:)), name: ActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(onDidEnterBackground), name: BackgroundNotification, object: nil)

        #if !os(watchOS)
        center.addObserver(self, selector: #selector(onWillTerminate(_:)), name: TerminateNotification, object: nil)
        #endif
    }

    @objc func onDidFinishLaunching(_ notification: NSNotification) {
        onLaunch?()
    }

    @objc func onDidBecomeActive(_ notification: NSNotification) {
        onActive?()
    }

    @objc func onDidEnterBackground(_ notification: NSNotification) {
        onBackground?()
    }

    @objc func onWillTerminate(_ notification: NSNotification) {
        onTermination?()
    }
}
