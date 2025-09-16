//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

public class BTTScreenTracker{
    
    private var hasViewing = false
    private var id = "\(Identifier.random())"
    private var pageName : String
    public  var type  = ScreenType.Manual.rawValue
    private var tracker : BTTScreenLifecycleTracker?
    
   // Add local object of
    public init(_ screenName : String){
        self.pageName = screenName
        self.tracker = BlueTriangle.screenTracker
    }
    
    private func updateScreenType(){
        
        if type == ScreenType.UIKit.rawValue{
            self.tracker?.setUpScreenType(.UIKit)
        }
        else if type == ScreenType.SwiftUI.rawValue{
            self.tracker?.setUpScreenType(.SwiftUI)
        }
        else{
            self.tracker?.setUpScreenType(.Manual)
        }
    }
    
    public func loadStarted() {
        self.hasViewing = true
        self.updateScreenType()
        self.tracker?.manageTimer(pageName, id: id, type: .load)
    }
    
    public func loadEnded() {
        if self.hasViewing{
            self.updateScreenType()
            self.tracker?.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        self.hasViewing = true
        self.updateScreenType()
        self.tracker?.manageTimer(pageName, id: id, type: .view)
    }
    
    public func viewingEnd() {
        if self.hasViewing{
            self.tracker?.manageTimer(pageName, id: id, type: .disappear)
            self.hasViewing = false
        }
    }
}

