# Using Timers

Create timers to measure responses to user interactions.

## Overview

To measure the duration of a user interaction, initialize a ``Page`` object describing that interation and pass it to ``BlueTriangle/BlueTriangle/startTimer(page:timerType:)`` to receive a running timer instance.

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.startTimer(page: page)
```

If you need to defer the start of the timer, use ``BlueTriangle/BlueTriangle/makeTimer(page:timerType:)`` and call the returned timer's ``start()`` method when you are ready to start timing:

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.makeTimer(page: page)
...
timer.start()
```

In both cases, pass your timer to ``BlueTriangle/BlueTriangle/endTimer(_:purchaseConfirmation:)`` to send it to the Blue Triangle server. 

```swift
BlueTriangle.endTimer(timer)
```

Running timers are automatically stopped when passed to ``BlueTriangle/BlueTriangle/endTimer(_:purchaseConfirmation:)``, though you can end timing earlier by calling the timer's ``end()`` method.

```swift
timer.end()
...
// You must still pass the timer to `BlueTriangle.endTimer(_:)` to send it to the Blue Triangle server
BlueTriangle.endTimer(timer)
```

For timers that are associated with checkout, create a ``PurchaseConfirmation`` object to pass along with the timer to ``BlueTriangle/BlueTriangle/endTimer(_:purchaseConfirmation:)``:

```swift
timer.end()
let purchaseConfirmation = PurchaseConfirmation(cartValue: 99.00)
BlueTriangle.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
```
