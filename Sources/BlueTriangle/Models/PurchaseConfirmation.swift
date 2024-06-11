//
//  PurchaseConfirmation.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object describing a purchase confirmation interaction.
final public class PurchaseConfirmation: NSObject {
    /// Used by server to deduplicate `PurchaseConfirmation`s.
    internal var pageValue: Decimal = 0.0

    /// Purchase amount for purchase confirmation steps.
    @objc public var cartValue: Decimal

    /// The order number from the purchase on purchase confirmation steps.
    @objc public var orderNumber: String
    
    /// Cart count  for purchase confirmation steps.
    @objc public var cartCount: Int = 0
    
    /// Cart checkout count  for purchase confirmation steps.
    @objc public var cartCheckoutCount: Int = 0

    /// Order time and date.
    @objc public var orderTime: TimeInterval = 0.0

    /// Creates a purchase confirmation.
    /// - Parameters:
    ///   - cartValue: Purchase amount.
    ///   - cartCount: Cart count.
    ///   - cartCheckoutCount: Cart checkout count
    ///   - orderNumber: Order number.
    @objc
    public init(cartValue: Decimal, cartCount: Int = 0, cartCheckoutCount: Int = 0, orderNumber: String = "") {
        self.cartValue = cartValue
        self.orderNumber = orderNumber
        self.cartCount = cartCount
        self.cartCheckoutCount = cartCheckoutCount
    }

    init(pageValue: Decimal = 0.0, cartValue: Decimal, cartCount: Int = 0, cartCheckoutCount: Int = 0, orderNumber: String, orderTime: TimeInterval = 0.0) {
        self.pageValue = pageValue
        self.cartValue = cartValue
        self.orderNumber = orderNumber
        self.orderTime = orderTime
        self.cartCount = cartCount
        self.cartCheckoutCount = cartCheckoutCount
    }
}

// MARK: - Equatable
public extension PurchaseConfirmation {
    static func == (lhs: PurchaseConfirmation, rhs: PurchaseConfirmation) -> Bool {
        return lhs.cartValue == rhs.cartValue
        && (lhs.orderNumber == rhs.orderNumber
            || (rhs.orderTime <= lhs.orderTime + TimeInterval.day
                && rhs.orderTime >= lhs.orderTime - TimeInterval.day))
    }
}

extension PurchaseConfirmation {
    func deduplicate(from previous: PurchaseConfirmation) {
        if self == previous {
            pageValue = cartValue
            cartValue = 0.0
        }
    }
}
