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

Initialize a `Page` object with your page properties and pass it to `BlueTriangle.startTimer(page:)` to receive a running timer instance.

```swift
let page = Page(pageName: "MY_PAGE")
let timer = BlueTriangle.startTimer(page: page)
```

If you need to defer the start of the timer, pass your `Page` instance to `BlueTriangle.makeTimer(page:)` and call the timer's `start()` method when you are ready to start timing:

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
