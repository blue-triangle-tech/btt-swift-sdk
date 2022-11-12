# Network Capture

The Blue Triangle SDK supports capturing network requests using either the `NetworkCaptureSessionDelegate` or `bt`-prefixed `URLSession` methods.

To enable network capture, configure the SDK with a non-zero network sample rate:

```swift
BlueTriangle.configure { config in
    ...
    config.networkSampleRate = 0.05
}
```

A value of `0.05`, for example, means that network capture will be randomly enabled for 5% of user sessions. Network requests using a `URLSession` with a `NetworkCaptureSessionDelegate` or made with one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started at the time a request completes. Note that requests are not associated with a timer until the request ends.

## `NetworkCaptureSessionDelegate`

Use `NetworkCaptureSessionDelegate` as your `URLSession` delegate to gather information about network requests when network capture is enabled.

```swift
let sesssion = URLSession(
    configuration: .default,
    delegate: NetworkCaptureSessionDelegate(),
    delegateQueue: nil)

let (data, response) = try await session.data(from: URL(string: "https://example.com")!)
```


## `URLSession` Methods

Use `bt`-prefixed `URLSession` methods to gather information about network requests when network capture is enabled.

The Blue Triangle SDK offers `bt`-prefixed versions of common `URLSession` methods that can be used to capture network requests:

| Standard                                       | Network Capture                                  |
| :--                                            | :--                                              |
| `URLSession.dataTask(with:completionHandler:)` | `URLSession.btDataTask(with:completionHandler:)` |
| `URLSession.data(for:delegate:)`               | `URLSession.btData(for:delegate:)`               |
| `URLSession.dataTaskPublisher(for:)`           | `URLSession.btDataTaskPublisher(for:)`           |

Use these methods just as you would their standard counterparts:

```swift
let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()
```

