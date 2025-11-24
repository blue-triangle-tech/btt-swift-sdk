//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

@preconcurrency
public final class BTTScreenTracker {
    
    private let lock = NSLock()
    private var hasViewing = false
    private var id = "\(Identifier.random())"
    private var pageName: String
    private var tracker: BTTScreenLifecycleTracker?
    private var type = ScreenType.Manual.rawValue
    
    public init(_ screenName: String) {
        self.pageName = screenName
        self.tracker = BlueTriangle.screenTracker
    }

    // MARK: - Private
    
    private func updateScreenType() {
        if type == ScreenType.UIKit.rawValue {
            tracker?.setUpScreenType(.UIKit)
        } else if type == ScreenType.SwiftUI.rawValue {
            tracker?.setUpScreenType(.SwiftUI)
        } else {
            tracker?.setUpScreenType(.Manual)
        }
    }
    
    public func loadStarted() {
        lock.sync {
            hasViewing = true
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .load)
        }
    }
    
    public func loadEnded() {
        lock.sync {
            guard hasViewing else { return }
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        lock.sync {
            hasViewing = true
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .view)
        }
    }
    
    public func viewingEnd() {
        lock.sync {
            guard hasViewing else { return }
            tracker?.manageTimer(pageName, id: id, type: .disappear)
            hasViewing = false
        }
    }
}

