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
        if isValidEvent(event) {
            fireCheckoutEvent()
        }
        lastEvent = event
    }
    
    private func fireCheckoutEvent() {
        if BlueTriangle.initialized,  let session = BlueTriangle.sessionData() {
            let timer = BlueTriangle.startTimer(
                page: Page(
                    pageName: Constants.autoCheckoutPageName))
            timer.nativeAppProperties.autoCheckout = true
            let purchaseConfirmation: PurchaseConfirmation = PurchaseConfirmation(
                cartValue: Decimal(session.checkOutAmount),
                cartCount: session.checkoutCartCount,
                cartCountCheckout:session.checkoutCartCountCheckout,
                orderNumber: session.checkoutOrderNumber,
                orderTime: TimeInterval(session.checkoutTimeValue))
            BlueTriangle.endTimer(
                timer,
                purchaseConfirmation: purchaseConfirmation)
        }
    }
}

extension CheckoutEventReporter {
    
    private func isValidEvent(_ event: CheckoutEvent) -> Bool {
        
        guard let session = BlueTriangle.sessionData(),
              session.checkoutTrackingEnabled else {
            return false
        }
        
        switch event {
        case let classEvent as ClassCheckoutEvent:
            // Prevent immediate duplicate
            if let last = lastEvent as? ClassCheckoutEvent,
               last.name == classEvent.name {
                return false
            }
            // Match against class names
            return session.checkoutClassName.contains { configuredName in
                configuredName
                    .localizedCaseInsensitiveContains(classEvent.name)
            }
            
            
        case let networkEvent as NetworkCheckoutEvent:
            // Prevent immediate duplicate
            if let last = lastEvent as? NetworkCheckoutEvent,
               last.url == networkEvent.url {
                return false
            }
            
            // Validate HTTP success range (200–299)
            let isSuccessStatus: Bool = {
                if let codeString = networkEvent.statusCode,
                   let code = Int(codeString) {
                    return (200...299).contains(code)
                }
                return false
            }()
            
            // Match URL using wildcard support
            let matchesURL = networkEvent.url
                .matchesWildcard(session.checkoutURL)
            return isSuccessStatus && matchesURL
            
            
        default:
            return false
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
