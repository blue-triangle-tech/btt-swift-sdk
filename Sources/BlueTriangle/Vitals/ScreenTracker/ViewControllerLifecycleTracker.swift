//
//  ViewControllerLifecycleTracker.swift
//
//
//  Created by JP on 13/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//


#if os(iOS)
import Foundation
import UIKit

fileprivate func swizzleMethod(_ cls: AnyClass, original: Selector, swizzled: Selector) -> (Method, Method)? {
    guard
        let originalMethod = class_getInstanceMethod(cls, original),
        let swizzledMethod = class_getInstanceMethod(cls, swizzled)
    else {
        BlueTriangle.screenTracker?.logger?.error("Swizzling failed: \(cls) \(original) ↔︎ \(swizzled)")
        return nil
    }

    method_exchangeImplementations(originalMethod, swizzledMethod)
    return (originalMethod, swizzledMethod)
}

extension UIApplication {
    
    func getReadableName(from view: UIView) -> String? {
        
        let className = String(describing: type(of: view))
        // UISegmentedControl
        if let segmented = view as? UISegmentedControl {
             let selectedIndex = segmented.selectedSegmentIndex
             if selectedIndex != UISegmentedControl.noSegment {
                 return "\(className) \(selectedIndex)"
             }
         }
        
        // UIButton title
        if let button = view as? UIButton,
           let title = button.title(for: .normal),
           !title.isEmpty {
            return title
        }

        // UILabel text
        if let label = view as? UILabel,
           let text = label.text,
           !text.isEmpty {
            return text
        }

        // Tab bar item label
        if let tabBarButton = view.superview,
           String(describing: type(of: tabBarButton)).contains("UITabBarButton"),
           let label = tabBarButton.subviews.compactMap({ $0 as? UILabel }).first,
           let text = label.text,
           !text.isEmpty {
            return text
        }

        // UIBarButtonItem (e.g. back button)
        if String(describing: type(of: view)).contains("UIButtonBarButton"),
           let label = view.subviews.compactMap({ $0 as? UILabel }).first,
           let text = label.text,
           !text.isEmpty {
            return text
        }

        // Accessibility label
        if view is UIControl {
            if let accLabel = view.accessibilityLabel, !accLabel.isEmpty {
                return accLabel
            }
        }

        // Only recurse into subviews
        if view is UIControl || String(describing: type(of: view)).contains("Button") {
            for subview in view.subviews {
                if let name = getReadableName(from: subview) {
                    return name
                }
            }
        }

        // Otherwise, return nil
        return nil
    }
    
    private func getActionableAncestor(from view: UIView?) -> UIView? {
        var current = view
        while let v = current {
            if v is UIControl ||
                v is UITableViewCell ||
                v is UICollectionViewCell ||
                String(describing: type(of: v)).contains("Button") ||
                String(describing: type(of: v)).contains("Cell") {
                return v
            }
            current = v.superview
        }
        return nil
    }
    
    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if let touches = event.allTouches {
            for touch in touches {
                guard touch.phase == .began else { continue }
                let location = touch.location(in: touch.window)
                if let tappedView = touch.window?.hitTest(location, with: event), let actionableView = self.getActionableAncestor(from: tappedView) {
                    if let name = getReadableName(from: actionableView), touch.tapCount > 0 {
                        let isDoubleTap = touch.tapCount == 2
                        let actionString = "User \(isDoubleTap ? "Double" : "") Tapped: \(name)"
                        print(actionString)
                        BlueTriangle.groupTimer.setGroupAction(actionString)
                    }
                }
                BlueTriangle.groupTimer.setLastAction(Date())
            }
        }
        swizzled_sendEvent(event)
    }
}

extension UIViewController{
    
    private static var isSwizzled = false
    private static var swizzledPairs: [(Method, Method)] = []
    
    static func setUp() {
        guard !isSwizzled else { return }
        
        if let didLoadPair = swizzleMethod(UIViewController.self, original: #selector(viewDidLoad), swizzled: #selector(viewDidLoad_Tracker)) {
            swizzledPairs.append(didLoadPair)
        }
        if let willAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewWillAppear(_:)), swizzled: #selector(viewWillAppear_Tracker(_:))) {
            swizzledPairs.append(willAppearPair)
        }
        if let didAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidAppear(_:)), swizzled: #selector(viewDidAppear_Tracker(_:))) {
            swizzledPairs.append(didAppearPair)
        }
        if let didDisappearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidDisappear(_:)), swizzled: #selector(viewDidDisappear_Tracker(_:))) {
            swizzledPairs.append(didDisappearPair)
        }
        
        if let sendEventPair = swizzleMethod(UIApplication.self, original: #selector(UIApplication.sendEvent(_:)), swizzled: #selector(UIApplication.swizzled_sendEvent(_:))) {
            swizzledPairs.append(sendEventPair)
        }
        
        isSwizzled = true
        BlueTriangle.screenTracker?.logger?.debug("View Screen Tracker: setup completed.")
    }
    
    static func removeSetUp() {
        guard isSwizzled else { return }
        
        for (original, swizzled) in swizzledPairs {
            method_exchangeImplementations(swizzled, original)
        }
        
        swizzledPairs.removeAll()
        isSwizzled = false
        BlueTriangle.screenTracker?.logger?.debug("View Screen Tracker: setup removed.")
    }
    
    /// Checks if the given object belongs to an Apple framework class.
    /// - Parameter object: The object to be checked.
    /// - Returns: `true` if the object's class is defined within an Apple framework; otherwise, `false`.
    private func isAppleClass(_ object: AnyObject) -> Bool {
        let objectBundle = Bundle(for: type(of: object))
        return objectBundle.bundleIdentifier?.starts(with: "com.apple") ?? false
    }
    
    /// Determines whether the current view controller should be tracked for analytics or other purposes.
    /// - Returns: `true` if the view controller is eligible for tracking; otherwise, `false`.
    func shouldTrackScreen() -> Bool{
        
        
        let bundle = Bundle(for: type(of: self))
           
        // Ignore classes whose names or superclasses start with an underscore
        // These are typically private or internal Apple system classes.
        if bundle != Bundle.main{
            
            let className = "\(type(of: self))"
            
            if className.hasPrefix("_") {
                return false
            }
            
            let superClassName = "\(type(of: self.superclass))"
            
            if superClassName.hasPrefix("_") {
                return false
            }
        }
        
        // Ignore any view controllers that belong to Apple frameworks
        if isAppleClass(self){
            return false
        }
        
        // Ignore spacific controllers to ignore Noise
        // Ignore specific noise-causing view controllers (custom-defined list)
        // These are common system-related view controllers that are not relevant for tracking.
        let excludedClasses: [String] = [
            "UIHostingController",             // SwiftUI hosting controller
            "UIInputWindowController",         // Handles keyboard input
            "UIEditingOverlayViewController",  // Overlay for text editing
            "NavigationStackHostingController",// SwiftUI navigation stack
            "UIPredictionViewController",      // Predictive typing view
            "UIPlaceholderPredictiveViewController",  // Placeholder for predictions
            "UlKeyboardMediaServiceRemoteViewController"
        ]
        
        let selfClassName = "\(type(of: self))"
        for excludedClass in excludedClasses {
            if selfClassName.contains(excludedClass) {
                return false
            }
        }
        
       // Ignore any view controllers explicitly listed in a developer exclusion list or remote config ignore list
        if let sessionData = BlueTriangle.sessionData(), sessionData.ignoreViewControllers.contains(selfClassName) {
            return false
        }
        
        //Ignore container and input view controllers
        // These are typically not standalone screens and are part of navigation or input handling.
        return !(self.isKind(of: UINavigationController.self)       // Navigation controller
                 || self.isKind(of: UITabBarController.self)         // Tab bar controller
                 || self.isKind(of: UISplitViewController.self)      // Split view controller
                 || self.isKind(of: UIPageViewController.self)       // Page view controller
                 || self.isKind(of: UIInputViewController.self)      // Input method controller
                 || self.isKind(of: UIAlertController.self))         // Alert controller
    }
    
    
    @objc dynamic func viewDidLoad_Tracker() {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.loadStarted(String(describing: self), getPageName(), isAutoTrack: true)
        }
        viewDidLoad_Tracker()
    }
    
    @objc dynamic func viewWillAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.loadFinish(String(describing: self), getPageName(), isAutoTrack: true)
        }
        viewWillAppear_Tracker(animated)
    }
                                
    @objc dynamic func viewDidAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.viewStart(String(describing: self), getPageName(), isAutoTrack: true)
        }
        viewDidAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidDisappear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.viewingEnd(String(describing: self), getPageName(), isAutoTrack: true)
        }
        viewDidDisappear_Tracker(animated)
    }

    func getPageName() -> String {
        
        let viewName = "\(type(of: self))"
        var pageName: String = viewName
        let currentTitle = self.navigationItem.title ?? ""
        
        if currentTitle.count > 0 {
            pageName = currentTitle
        } 
        
        let isGroupTimer = BlueTriangle.configuration.enableGrouping
        if !isGroupTimer {
            pageName = viewName
        } else {
            if pageName != viewName {
                pageName = viewName + " - " + pageName
            }
        }

        return pageName
    }
}

#endif
