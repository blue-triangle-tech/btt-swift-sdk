//
//  PurchaseConfirmation.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// An object describing a purchase confirmation interaction.
final public class PurchaseConfirmation: NSObject, @unchecked Sendable {
    private let lock = NSLock()

    private var _pageValue: Decimal = 0.0
    private var _cartValue: Decimal
    private var _orderNumber: String
    private var _cartCount: Int = 0
    private var _cartCountCheckout: Int = 0
    private var _orderTime: TimeInterval = 0.0

    /// Used by server to deduplicate `PurchaseConfirmation`s.
    internal var pageValue: Decimal {
        get { lock.sync { _pageValue } }
        set { lock.sync { _pageValue = newValue } }
    }
    
    /// Purchase amount for purchase confirmation steps.
    @objc public var cartValue: Decimal {
        get { lock.sync { _cartValue } }
        set { lock.sync { _cartValue = newValue } }
    }
    
    /// The order number from the purchase on purchase confirmation steps.
    @objc public var orderNumber: String {
        get { lock.sync { _orderNumber } }
        set { lock.sync { _orderNumber = newValue } }
    }
    
    /// Cart count  for purchase confirmation steps.
    @objc public var cartCount: Int {
        get { lock.sync { _cartCount } }
        set { lock.sync { _cartCount = newValue } }
    }
    
    /// Cart count checkout  for purchase confirmation steps.
    @objc public var cartCountCheckout: Int {
        get { lock.sync { _cartCountCheckout } }
        set { lock.sync { _cartCountCheckout = newValue } }
    }
    
    /// Order time and date.
    @objc public var orderTime: TimeInterval {
        get { lock.sync { _orderTime } }
        set { lock.sync { _orderTime = newValue } }
    }
    
    /// Creates a purchase confirmation.
    /// - Parameters:
    ///   - cartValue: Purchase amount.
    ///   - cartCount: Cart count.
    ///   - cartCountCheckout: Cart checkout count
    ///   - orderNumber: Order number.
    @objc
    public init(
        cartValue: Decimal,
        cartCount: Int = 0,
        cartCountCheckout: Int = 0,
        orderNumber: String = ""
    ) {
        _cartValue = cartValue
        _orderNumber = orderNumber
        _cartCount = cartCount
        _cartCountCheckout = cartCountCheckout
    }

    @objc
    public init(
        pageValue: Decimal = 0.0,
        cartValue: Decimal,
        cartCount: Int = 0,
        cartCountCheckout: Int = 0,
        orderNumber: String,
        orderTime: TimeInterval = 0.0
    ) {
        _pageValue = pageValue
        _cartValue = cartValue
        _orderNumber = orderNumber
        _orderTime = orderTime
        _cartCount = cartCount
        _cartCountCheckout = cartCountCheckout
    }

    // MARK: - Equality + dedup using snapshots

    private func snapshot() -> (pageValue: Decimal, cartValue: Decimal, orderNumber: String, orderTime: TimeInterval) {
        lock.sync {
            (_pageValue, _cartValue, _orderNumber, _orderTime)
        }
    }
}
// MARK: - Equatable
public extension PurchaseConfirmation {
    static func == (lhs: PurchaseConfirmation, rhs: PurchaseConfirmation) -> Bool {
          let a = lhs.snapshot()
          let b = rhs.snapshot()

          return a.cartValue == b.cartValue && (a.orderNumber == b.orderNumber || ( b.orderTime <= a.orderTime + TimeInterval.day && b.orderTime >= a.orderTime - TimeInterval.day))
      }
}

extension PurchaseConfirmation {
    func deduplicate(from previous: PurchaseConfirmation) {
        if self == previous {
            lock.sync {
                _pageValue = _cartValue
                _cartValue = 0.0
            }
        }
    }
}
