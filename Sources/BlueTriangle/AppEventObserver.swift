//
//  AppEventObserver.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

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
        center.addObserver(self, selector: #selector(onDidFinishLaunching(_:)), name: .finishedLaunching, object: nil)
        center.addObserver(self, selector: #selector(onDidBecomeActive(_:)), name: .becameActive, object: nil)
        center.addObserver(self, selector: #selector(onDidEnterBackground), name: .enteredBackground, object: nil)

        #if !os(watchOS)
        center.addObserver(self, selector: #selector(onWillTerminate(_:)), name: .willTerminate, object: nil)
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
