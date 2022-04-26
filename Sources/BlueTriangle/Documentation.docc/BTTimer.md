# Using Timers

Create timers to measure responses to user interactions.

## Overview

Initialize a `Page` object with your page properties and pass it to `BlueTriangle.startTimer(page:)` to receive a running `BTTimer` instance.

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.startTimer(page: page)
```

If you need to defer the start of the timer, pass your `Page` instance to `BlueTriangle.makeTimer(page: page)` and call the timer's `start()` method when you are ready to start timing:

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.makeTimer(page: page)
...
timer.start()
```

In both cases, pass your timer to `BlueTriangle.endTimer(_:purchaseConfirmation:)` to send it to the Blue Triangle server. 

```swift
BlueTriangle.endTimer(timer)
```

This automatically stops the timer, though you can end timing earlier by calling the timer's `end()` method.

```swift
timer.end()
...
// You must still pass the timer to `BlueTriangle.endTimer(_:)` to send it to the Blue Triangle server
BlueTriangle.endTimer(timer)
```

For timers that are associated with checkout, create a `PurchaseConfirmation` object and pass that along with the timer to `BlueTriangle.endTimer()`

```swift
timer.end()
let purchaseConfirmation = PurchaseConfirmation(cartValue: 99.00)
BlueTriangle.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
```
