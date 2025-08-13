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
import SwiftUI

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
    
    func getReadableName(from view: UIView) -> String {
        let className = String(describing: type(of: view))
        let accessibilityIdentifier = view.accessibilityIdentifier
        let idSuffix = accessibilityIdentifier.map { "&id=\($0)" } ?? ""
        
        // UISegmentedControl
        if let segmented = view as? UISegmentedControl {
            let selectedIndex = segmented.selectedSegmentIndex
            if selectedIndex != UISegmentedControl.noSegment {
                return "\(className)?position=\(selectedIndex)\(idSuffix)"
            }
        }

        // Table Cell
        if let cell = view.superview(of: UITableViewCell.self),
           let tableView = cell.superview(of: UITableView.self),
           let indexPath = tableView.indexPath(for: cell) {
            return "TableCell?position=[\(indexPath.section), \(indexPath.row)]\(idSuffix)"
        }

        // Collection Cell
        if let cell = view.superview(of: UICollectionViewCell.self),
           let collectionView = cell.superview(of: UICollectionView.self),
           let indexPath = collectionView.indexPath(for: cell) {
            return "CollectionCell?position=[\(indexPath.section), \(indexPath.item)]\(idSuffix)"
        }

        // Tab Bar Item
        if let tabBarButton = view.superview(ofClassNamed: "UITabBarButton"),
           let tabBar = tabBarButton.superview,
           let index = tabBar.subviews.firstIndex(of: tabBarButton) {
            return "TabBarItem?position=\(index)\(idSuffix)"
        }

        // Navigation Bar Item
        if className.contains("UIButtonBarButton"),
           let navBar = view.superview,
           let index = navBar.subviews.firstIndex(of: view) {
            return "NavBarButton?position=\(index)\(idSuffix)"
        }

        // UIButton
        if let button = view as? UIButton,
           let parent = button.superview,
           let index = parent.subviews.firstIndex(of: button) {
            return "UIButton?position=\(index)\(idSuffix)"
        }

        // UITextField
        if view is UITextField {
            return "UITextField\(idSuffix)"
        }

        // SwiftUI Hosting / Gesture views
        if className.contains("Hosting") || className.contains("Gesture") || className.contains("SwiftUI") {
            if let parent = view.superview,
               let index = parent.subviews.firstIndex(of: view) {
                return "SwiftUIView (\(className))?position=\(index)\(idSuffix)"
            } else {
                return "SwiftUIView (\(className))\(idSuffix)"
            }
        }

        // UIControl fallback
        if view is UIControl {
            if let parent = view.superview,
               let index = parent.subviews.firstIndex(of: view) {
                return "\(className)?position=\(index)\(idSuffix)"
            } else {
                return "\(className)\(idSuffix)"
            }
        }

        // Absolute fallback
        return "UnknownActionable (\(className))\(idSuffix)"
    }
    
    private func getActionableAncestor(from view: UIView?) -> UIView? {
        var current = view
        while let v = current {
            let className = String(describing: type(of: v))

            if v is UIControl ||
                v is UITableViewCell ||
                v is UICollectionViewCell ||
                v is UITextField ||
                className.contains("Button") ||
                className.contains("Cell") ||
                className.contains("Gesture") ||
                className.contains("Hosting") ||
                className.contains("SwiftUI") {
                return v
            }

            current = v.superview
        }
        return nil
    }
    
    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if let touches = event.allTouches {
            for touch in touches where touch.phase == .began {
                let location = touch.location(in: touch.window)
                if let tappedView = touch.window?.hitTest(location, with: event),
                   let actionableView = self.getActionableAncestor(from: tappedView) {
                    
                    let name = getReadableName(from: actionableView)
                    if touch.tapCount > 0 {
                        let formattedX = String(format: "%.2f", location.x)
                        let formattedY = String(format: "%.2f", location.y)
                        let isDoubleTap = touch.tapCount == 2
                        let actionType = "\(isDoubleTap ? "Double" : "")Tap"
                        let actionString = "\(name)&x=\(formattedX)&y=\(formattedY)"
                        let action = UserAction(action: actionString, actionType: actionType)
                        BlueTriangle.groupTimer.recordAction(action)
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

extension UIView {
    func superview<T: UIView>(of type: T.Type) -> T? {
        return superview as? T ?? superview?.superview(of: type)
    }

    func superview(ofClassNamed className: String) -> UIView? {
        if NSStringFromClass(type(of: self)).contains(className) {
            return self
        } else {
            return self.superview?.superview(ofClassNamed: className)
        }
    }
}
#endif
