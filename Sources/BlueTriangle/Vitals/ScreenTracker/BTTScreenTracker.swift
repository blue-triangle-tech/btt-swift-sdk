//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

public final class BTTScreenTracker : Sendable {
    
    class Storage: @unchecked Sendable {
        private let lock = NSLock()
        private var _hasViewing: Bool = false
        private var _type: String = ScreenType.Manual.rawValue
        
        internal var hasViewing: Bool {
            get { lock.sync { _hasViewing } }
            set { lock.sync { _hasViewing = newValue } }
        }
        
        internal var type: String {
            get { lock.sync { _type } }
            set { lock.sync { _type = newValue } }
        }
    }
    
    private let storage = Storage()
    private let pageName: String
    private let id: String = "\(Identifier.random())"
    private let screenTrackingTask = ScreenTrackingTask()
    
    public init(_ screenName: String) {
        self.pageName = screenName
    }

    // MARK: - Private
    private func updateScreenType() async {
        if storage.type == ScreenType.UIKit.rawValue {
            await BlueTriangle.getScreenTracker()?.setUpScreenType(.UIKit)
        } else if storage.type == ScreenType.SwiftUI.rawValue {
            await BlueTriangle.getScreenTracker()?.setUpScreenType(.SwiftUI)
        } else {
            await BlueTriangle.getScreenTracker()?.setUpScreenType(.Manual)
        }
    }
    
    public func loadStarted() {
        let time  = Date().timeIntervalSince1970
        screenTrackingTask.enqueue { [weak self] in
            guard let self = self else { return }
            self.storage.hasViewing = true
            await self.updateScreenType()
            await BlueTriangle.getScreenTracker()?.manageTimer(self.pageName, id: self.id, type: .load, time)
        }
    }
    
    public func loadEnded() {
        let time  = Date().timeIntervalSince1970
        screenTrackingTask.enqueue { [weak self] in
            guard let self = self, self.storage.hasViewing else { return }
            await self.updateScreenType()
            await BlueTriangle.getScreenTracker()?.manageTimer(self.pageName, id: self.id, type: .finish, time)
        }
    }

    public func viewStart() {
        let time  = Date().timeIntervalSince1970
        screenTrackingTask.enqueue { [weak self] in
            guard let self = self else { return }
            self.storage.hasViewing = true
            await self.updateScreenType()
            await BlueTriangle.getScreenTracker()?.manageTimer(self.pageName, id: self.id, type: .view, time)
        }
    }
    
    public func viewingEnd() {
        let time  = Date().timeIntervalSince1970
        screenTrackingTask.enqueue {  [weak self] in
            guard let self = self, self.storage.hasViewing else { return }
            await BlueTriangle.getScreenTracker()?.manageTimer(self.pageName, id: self.id, type: .disappear, time)
            self.storage.hasViewing = false
        }
    }
}

