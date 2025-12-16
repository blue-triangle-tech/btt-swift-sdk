//
//  ViewLifecycleTrackerModifier.swift
//
//
//  Created by JP on 20/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

  import SwiftUI

internal struct ViewLifecycleTrackerModifier: ViewModifier {
    private let screenTrackingTask = ScreenTrackingTask()
    internal let name: String
    @State var id : String?
    
    func body(content: Content) -> some View {
            
        if #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *){
            content
                .task({
                    if let id = self.id{
                        let time  = Date().timeIntervalSince1970
                        screenTrackingTask.enqueue {
                            await BlueTriangle.getScreenTracker()?.loadFinish(id, name, "", time)
                            await BlueTriangle.getScreenTracker()?.viewStart(id, name, "", time)
                        }
                    }
                })
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        let time  = Date().timeIntervalSince1970
                        screenTrackingTask.enqueue {
                            await BlueTriangle.getScreenTracker()?.loadStarted(id, name, "", time)
                        }
                    }
                }
                .onDisappear{
                    if let id = self.id{
                        let time  = Date().timeIntervalSince1970
                        screenTrackingTask.enqueue {
                            await BlueTriangle.getScreenTracker()?.viewingEnd(id, name, "", time)
                        }
                    }
                }
        }
        else{
            content
                .onAppear {
                    id = UUID().uuidString
                    if let id = self.id{
                        let time  = Date().timeIntervalSince1970
                        screenTrackingTask.enqueue {
                            await BlueTriangle.getScreenTracker()?.loadStarted(id, name, "", time)
                        }
                    }
                    if let id = self.id{
                        let time  = Date().timeIntervalSince1970
                        screenTrackingTask.enqueue {
                            await BlueTriangle.getScreenTracker()?.loadFinish(id, name, "", time)
                            await BlueTriangle.getScreenTracker()?.viewStart(id, name, "", time)
                        }
                    }
                }
                .onDisappear{
                    let time  = Date().timeIntervalSince1970
                    if let id = self.id{
                        screenTrackingTask.enqueue  {
                            await BlueTriangle.getScreenTracker()?.viewingEnd(id, name, "", time)
                        }
                    }
                }
        }
    }
}

public extension View {
    
    private func shouldTrackScreen(_ name : String) -> Bool{

        setUpScreenType()
        
        // Ignore any view explicitly listed in a developer exclusion list or remote config ignore list
        if let sessionData = BlueTriangle.sessionData(), sessionData.ignoreViewControllers.contains(name) {
             return false
         }
        
        return true
    }
    
    private func setUpScreenType() {
        Task {
            await BlueTriangle.getScreenTracker()?.setUpScreenType(.SwiftUI)
        }
    }
    
    ///Uses for manual screen tracking to log individual views in SwiftUI.
    ///To track screen, call "trackScreen(_ screenName: String)" on view which screen compose(which life cycle you want to track) like VStack().trackScreen("ContentView") or  ContentView().trackScreen("ContentView")
    ///This method track screen when this view appears on screen
    
    
    @ViewBuilder
    func bttTrackScreen(_ screenName: String) -> some View {
        if shouldTrackScreen(screenName) {
             self.modifier(ViewLifecycleTrackerModifier(name: screenName))
        } else {
            self
        }
    }
}


