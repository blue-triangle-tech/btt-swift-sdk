//
//  CheckoutEventReporter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/02/26.
//

import Foundation

protocol CheckoutEvent {}

final actor CheckoutEventReporter {
    
    private var lastEvent: CheckoutEvent?
    
    func onCheckoutEvent(_ event: CheckoutEvent) {
        guard let session = BlueTriangle.sessionData(), session.checkoutTrackingEnabled else { return }
        switch event {
            
        case let classEvent as ClassCheckoutEvent:
            handleClassEvent(classEvent)
            
        case let networkEvent as NetworkCheckoutEvent:
            handleNetworkEvent(networkEvent)
            
        default:
            break
        }
        
        lastEvent = event
    }
    
    private func handleClassEvent(_ event: ClassCheckoutEvent) {
        print("Checkout event fired ---- \(event.name)")
        if let lastEvent = lastEvent as? ClassCheckoutEvent, lastEvent.name == event.name { return }
        if let session = BlueTriangle.sessionData(), session.checkoutClassName.contains(event.name) {
            fireCheckoutEvent()
        }
    }
    
    private func handleNetworkEvent(_ event: NetworkCheckoutEvent) {
        
        if let lastEvent = lastEvent as? NetworkCheckoutEvent, lastEvent.url == event.url { return }
        
        if  let session = BlueTriangle.sessionData(), event.statusCode == "200" &&
                event.url.matchesWildcard(session.checkoutURL) {
            fireCheckoutEvent()
        }
    }
    
    private func isValidEvent(_ event: CheckoutEvent) -> Bool {
       return true
    }
    
    private func fireCheckoutEvent() {
        if BlueTriangle.initialized,  let session = BlueTriangle.sessionData() {
            let timer = BlueTriangle.startTimer(
                page: Page(
                    pageName: Constants.autoCheckoutPageName))
            BlueTriangle.endTimer(
                timer,
                purchaseConfirmation: PurchaseConfirmation(
                    cartValue: Decimal(session.checkOutAmount),
                    cartCount: session.checkoutCartCount,
                    cartCountCheckout:session.checkoutCartCountCheckout,
                    orderNumber: session.checkoutOrderNumber,
                    orderTime: TimeInterval(session.checkoutTimeValue)))
        }
    }
}

struct ClassCheckoutEvent: CheckoutEvent {
    var name: String
}

struct NetworkCheckoutEvent: CheckoutEvent {
    var url: String
    var statusCode: String?
}
