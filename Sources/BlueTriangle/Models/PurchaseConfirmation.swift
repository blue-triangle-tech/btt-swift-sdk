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

    /// Order time and date.
    @objc public var orderTime: TimeInterval = 0.0

    /// Creates a purchase confirmation.
    /// - Parameters:
    ///   - cartValue: Purchase amount.
    ///   - orderNumber: Order number.
    @objc
    public init(cartValue: Decimal, orderNumber: String = "") {
        self.cartValue = cartValue
        self.orderNumber = orderNumber
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
