# Blue Triangle SDK for iOS

Blue Triangle analytics SDK for iOS.

## Installation

## Installation using Swift Packages

To install BTT using Swift Packages in your iOS project, you need to follow these steps:

Xcode 13: go to **File > Add Packages…**, enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, and click **Add Package**.

Xcode 11 - 12: go to **File > Swift Packages > Add Package Dependency…** and enter the package repository URL `https://github.com/blue-triangle-tech/btt-swift-sdk.git`, then follow the instructions.

## Installation using CocoaPods

To install BTT using CocoaPods in your iOS project, you need to follow these steps:

### Install CocoaPods (*Skip that step if already installed CocoaPods*)

  1. **Install CocoaPods** : Open Terminal and exicute following command:
 
  ```
    sudo gem install cocoapods
  ```
  
  2. **Setup CocoaPods** : After installation done, Next, you need to setup the CocoaPods master repository. Type in the terminal:
 
  ```
    pod setup
  ```
   Once done, it will output "Setup Complete", and you can create your Xcode project and save it


### Install BlueTriangle To Your Project
  
  1. **Create a Podfile** (*Skip that step if 'Podfile' already Exists*):  Navigate to your project directory in the terminal and create a Podfile by running:
 
   ```
    pod init
  ```
  
   2. **Open the Podfile:** : Then open your project's podfile by typing in terminal:
  
   ```
    open -a Xcode Podfile
  ```
  
   3. **Edit the Podfile:** : Your Podfile will get open in text mode. Initially there will be some default commands in there. Here is where you add following :
  
   ```
      pod 'BlueTriangleSDK-Swift'     
  ```

   4. **Install Pods**: Save the Podfile and run the following command in the terminal to install the dependencies:
    
    ```
      pod install     
    ```

   5. **Open the Workspace**: Close your Xcode project and open the newly created .xcworkspace file. This file contains your project along with the CocoaPods dependencies.
   
   6. **Use the Pods**: You can now import and use the dependencies in your project. For example, to use BlueTriangle, you would import it in your Swift file:
   
    ```
      import BlueTriangle
    ```
    That's it! Your dependencies should now be installed and ready to use in your iOS project.


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

#### Timer Types

`BlueTriangle.makeTimer(page:timerType:)` and `BlueTriangle.startTimer(page:timerType:)` have a `timerType` parameter to specify the type of the timer they return. By default, both methods return main timers with the type `BTTimer.TimerType.main`. When network capture is enabled, requests made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time the request completes. It is recommended to only have a single main timer running at any given time. If you need overlapping timers, create additional custom timers by specifying a `BTTimer.TimerType.custom` timer type:

```swift
let mainTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
let customTimer = BlueTriangle.startTimer(page: Page(pageName: "MY_OTHER_TIMER"), timerType: .custom)
// ...
BlueTriangle.endTimer(mainTimer)
// ...
BlueTriangle.endTimer(customTimer)
```

### Network Capture

The Blue Triangle SDK supports capturing network requests using either the `NetworkCaptureSessionDelegate` or `bt`-prefixed `URLSession` methods.

To enable network capture, first configure the SDK with a non-zero network sample rate:

```swift
BlueTriangle.configure { config in
    ...
    config.networkSampleRate = 0.05
}
```

A value of `0.05`, for example, means that network capture will be randomly enabled for 5% of user sessions. Network requests using a `URLSession` with a `NetworkCaptureSessionDelegate` or made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time a request completes. Note that requests are only captured after at least one main timer has been started and they are not associated with a timer until the request ends.

#### `NetworkCaptureSessionDelegate`

You can use `NetworkCaptureSessionDelegate` or a subclass as your `URLSession` delegate to gather information about network requests when network capture is enabled:

```swift
let sesssion = URLSession(
    configuration: .default,
    delegate: NetworkCaptureSessionDelegate(),
    delegateQueue: nil)

let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
let (data, response) = try await session.data(from: URL(string: "https://example.com")!)
```

#### `URLSession` Methods

Alternatively, use `bt`-prefixed `URLSession` methods to capture network requests:

| Standard                                       | Network Capture                                  |
| :--                                            | :--                                              |
| `URLSession.dataTask(with:completionHandler:)` | `URLSession.btDataTask(with:completionHandler:)` |
| `URLSession.data(for:delegate:)`               | `URLSession.btData(for:delegate:)`               |
| `URLSession.dataTaskPublisher(for:)`           | `URLSession.btDataTaskPublisher(for:)`           |

Use these methods just as you would their standard counterparts:

```swift
let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
...
URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()
```

### Mannual Network Capture

For other network capture requirements, captured requests can be manually created and submitted to the tracker.

```swift
let tracker = NetworkCaptureTracker.init(url: "https://hub.dummyapis.com/delay?seconds=3", method: "post", requestBodylength: 9130)
tracker.submit(200, responseBodyLength: 11120, contentType: "json")
```


### Screen View Tracking

All UIViewControllers view count can be tracked. Setting "enableScreenTracking"  configuration property to true will capture view counts of every UIViewController in your app. You can see each view controller name with there count on our dashboard.

```swift
 BlueTriangle.configure { config in
         ...
         config.enableScreenTracking = true
     }
```

SwiftUI views are not captured automatically. You need to call bttTrackScreen(<screen Name>) modifier on each view which you want to track. Below example show usage of "bttTrackScreen(_ screenName: String)" to track About Us screen.

```swift
struct ContentView: View {
    var body: some View {
        VStack{
            Text("Hello, world!")
        }
        .bttTrackScreen("Demo_Screen")
    }
}
```

### ANR Detection

ANR(Application Not Responding) detects to main thread in which an app becomes unresponsive or stops responding to user input for an extended period of time. It can be enabled by setting "ANRMonitoring" configuration property to "true". And it can set Interval, to consider it an ANR situation by setting "ANRWarningTimeInterval" configuration property as shown below.


```swift
 BlueTriangle.configure { config in
         ...
         config.ANRMonitoring = true
         config.ANRWarningTimeInterval = 3
     }
```
By default, the ANR interval is set to 5 seconds.


### Memory Warning

A "Memory Warning" is raise to a situation where an application is consuming a significant amount of memory, and the operating system is notifying your app that it should release any unnecessary resources to free up memory. It can be enabled by setting "enableMemoryWarning" configuration property to "true".


```swift
 BlueTriangle.configure { config in
         ...
         config.enableMemoryWarning = true
     }
```


### Network State

 A "Network State" feature is used to monitoring state of network ( like - wifi, offline, online etc. ) and provided time period of each used state (i.e provide usege of each network state). It can be enabled by setting "enableTrackingNetworkState" configuration property to "true".


```swift
 BlueTriangle.configure { config in
         ...
         config.enableTrackingNetworkState = true
     }
```
