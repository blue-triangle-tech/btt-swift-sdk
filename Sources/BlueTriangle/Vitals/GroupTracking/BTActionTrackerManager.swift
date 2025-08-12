//
//  BTActionTrackerManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/08/25.
//

final class BTActionTrackerManager {
    private var activeTrackings: [BTActionTracker] = []
    
    func startTracking() {
        self.stopTracking()
        activeTrackings.append(BTActionTracker())
    }
    
    func recordAction(_ action: String) {
        if let activeTracking = activeTrackings.last(where: { $0.isActiveTracking }) {
            activeTracking.recordAction(action)
        }
    }
    
    func uploadActions(_ page : String, pageStartTime : Millisecond) {
        if let activeTracking = activeTrackings.last(where: { !$0.isActiveTracking }) {
            activeTracking.uploadActions(page, pageStartTime: pageStartTime)
            self.removeTracker(activeTracking)
        }
    }
    
    private func stopTracking() {
        if let activeTracking = activeTrackings.last(where: { $0.isActiveTracking }) {
            activeTracking.stopTracking()
        }
    }
    
    private func removeTracker(_ activeTracking: BTActionTracker) {
        activeTrackings.removeAll { $0 === activeTracking }
    }
}
