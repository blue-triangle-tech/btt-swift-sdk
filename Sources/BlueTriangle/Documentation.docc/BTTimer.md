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

### Timer Types

``BlueTriangle/BlueTriangle/makeTimer(page:timerType:)`` and ``BlueTriangle/BlueTriangle/startTimer(page:timerType:)`` have a `timerType` parameter to specify the type of the timer they return. By default, both methods return main timers with the type ``BlueTriangle/BTTimer/TimerType/main``. When <doc:NetworkCapture> is enabled, requests made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time the request completes. It is recommended to only have a single main timer running at any given time. If you need overlapping timers, create additional custom timers by specifying a ``BlueTriangle/BTTimer/TimerType/custom`` timer type:

```swift
let mainTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
let customTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_OTHER_TIMER"), timerType: .custom)
// ...
BlueTriangle.endTimer(mainTimer)
// ...
BlueTriangle.endTimer(customTimer)
```
