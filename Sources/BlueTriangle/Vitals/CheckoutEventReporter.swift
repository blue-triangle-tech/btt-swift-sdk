//
//  CheckoutEventReporter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/02/26.
//

import Foundation

protocol CheckoutEvent {}

final actor CheckoutEventReporter {
    
    private var lastNetworkEvent: NetworkCheckoutEvent?
    private var lastClassEvent: ClassCheckoutEvent?
    
    func onCheckoutEvent(_ event: CheckoutEvent) {
        if isValidEvent(event) {
            fireCheckoutEvent()
        }
    }
    
    private func fireCheckoutEvent() {
        if BlueTriangle.initialized,  let session = BlueTriangle.sessionData() {
            let timer = BlueTriangle.startTimer(
                page: Page(
                    pageName: Constants.autoCheckoutPageName))
            timer.nativeAppProperties.autoCheckout = true
            let purchaseConfirmation: PurchaseConfirmation = PurchaseConfirmation(
                cartValue: Decimal(session.checkoutAmount),
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
            if let last = lastClassEvent,
               last.name == classEvent.name {
                return false
            }
            lastClassEvent = classEvent
            print("Reported Event Checkout  Page : \(classEvent.name)")
            // Match against class names
            return session.checkoutClassName.contains { configuredName in
                configuredName
                    .localizedCaseInsensitiveContains(classEvent.name)
            }
            
            
        case let networkEvent as NetworkCheckoutEvent:
            // Prevent immediate duplicate
            if let last = lastNetworkEvent,
               last.url == networkEvent.url {
                return false
            }
            
            lastNetworkEvent = networkEvent
            
            let matchesURL = networkEvent.url
                .matchesWildcard(session.checkoutURL)
            
            if !matchesURL {
                return false
            }
            
            print("Reported Event Checkout  Url : \(networkEvent.url)")
            // Validate HTTP success range (200–299)
            let isSuccessStatus: Bool = {
                if let codeString = networkEvent.statusCode,
                   let code = Int(codeString) {
                    return (200...299).contains(code)
                }
                return false
            }()
            
            // Match URL using wildcard support

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
