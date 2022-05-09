# Blue Triangle SDK for iOS

Blue Triangle analytics SDK for iOS.

## Installation

Xcode 13: go to **File > Add Packages…**, enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, and click **Add Package**.

Xcode 11 - 12: go to **File > Swift Packages > Add Package Dependency…** and enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, then follow the instructions.

## Usage

### Configuration

Before sending timers you must first configure `BlueTriangle`. It is recommended to do this in your `AppDelegate.application(_:didFinishLaunchingWithOptions:)` method:

```swift
BlueTriangle.configure { config in
    config.siteID = "MY_SITE_ID"
    config.isReturningVisitor = true
    config.abTestID = "MY_AB_TEST_ID"
    config.campaignMedium = "MY_CAMPAIGN_MEDIUM"
    config.campaignName = "MY_CAMPAIGN_NAME"
    config.campaignSource = "MY_CAMPAIGN_SOURCE"
    config.dataCenter = "MY_DATA_CENTER"
    config.trafficSegmentName = "MY_SEGMENT_NAME"    
    config.crashTracking = .nsException
    config.performanceMonitorSampleRate = 1.0
}
```

### Timers

To measure the duration of a user interaction, initialize a `Page` object describing that interaction and pass it to `BlueTriangle.startTimer(page:timerType)` to receive a running timer instance.

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.startTimer(page: page)
```

If you need to defer the start of the timer, pass your `Page` instance to `BlueTriangle.makeTimer(page:timerType)` and call the timer's `start()` method when you are ready to start timing:

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

Running timers are automatically stopped when passed to `BlueTriangle.endTimer(_:purchaseConfirmation:)`, though you can end timing earlier by calling the timer's `end()` method.

```swift
timer.end()
...
// You must still pass the timer to `BlueTriangle.endTimer(_:)` to send it to the Blue Triangle server
BlueTriangle.endTimer(timer)
```

For timers that are associated with checkout, create a `PurchaseConfirmation` object to pass along with the timer to `BlueTriangle.endTimer(_:purchaseConfirmation:)`:

```swift
timer.end()
let purchaseConfirmation = PurchaseConfirmation(cartValue: 99.00)
BlueTriangle.endTimer(timer, purchaseConfirmation: purchaseConfirmation)
```

### Network Capture

Network capture is randomly enabled based on `BlueTriangleConfiguration.networkSampleRate`; a value of `0.05` means that 5% of sessions will be tracked. If enabled, network capture begins after the first call to `BlueTriangle.startSpan(page:)`:

```swift
let firstPage = Page(pageName: "MY_PAGE")
let spanTimer = BlueTriangle.startSpan(page: firstPage)

URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()
```

The Blue Triangle SDK offers `bt`-prefixed versions of common `URLSession` methods:

| Standard                                       | Network Capture                                  |
| :--                                            | :--                                              |     
| `URLSession.dataTask(with:completionHandler:)` | `URLSession.btDataTask(with:completionHandler:)` |
| `URLSession.data(for:delegate:)`               | `URLSession.btData(for:delegate:)`               |
| `URLSession.dataTaskPublisher(for:)`           | `URLSession.btDataTaskPublisher(for:)`           |

After this initial call to `startSpan(page:)`, there will always be one active span with which new requests make via one of the `bt`-prefixed `URLSession` methods are associated. Unlike the `BTTimer` instance returned from `makeTimer(page:)` and `startTimer(page:)`, the timer instance returned from `startSpan(page:)` does not need to be retained and passed to `endTimer(_:purchaseConfirmation)`. If the current span's timer has not already sent to Blue Triangle, it will be ended automatically and uploaded when a new span is started:

```swift
// `spanTimer` is ended and uploaded to Blue Triangle
let newSpanTimer = BlueTriangle.startSpan(page: Page(pageName: "ANOTHER_PAGE"))

// New requests made through one of the `bt`-prefixed `URLSession` methods are associated with `ANOTHER_PAGE`

...

// Optional
BlueTriangle.endTimer(newSpanTimer)
```

A span continues to be active until a new one is started even if its timer has been ended.
