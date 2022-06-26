# Network Capture

Use `bt`-prefixed `URLSession` methods to gather information about network requests when network capture is enabled.

The Blue Triangle SDK offers `bt`-prefixed versions of common `URLSession` methods that can be used to gather information about network requests when network capture is enabled:

| Standard                                       | Network Capture                                  |
| :--                                            | :--                                              |
| `URLSession.dataTask(with:completionHandler:)` | `URLSession.btDataTask(with:completionHandler:)` |
| `URLSession.data(for:delegate:)`               | `URLSession.btData(for:delegate:)`               |
| `URLSession.dataTaskPublisher(for:)`           | `URLSession.btDataTaskPublisher(for:)`           |

To enable network capture, configure the SDK with a non-zero network sample rate:

```swift
BlueTriangle.configure { config in
    ...
    config.networkSampleRate = 0.05
}
```

A value of `0.05`, for example, means that network capture will be randomly enabled for 5% of user sessions. Network requests made using one of the `bt`-prefixed `URLSession` methods will be associated with the last main timer to have been started when a request completes:

```swift
let timer = BlueTriangle.startTimer(page: Page(pageName: "MY_PAGE"))
URLSession.shared.btDataTask(with: URL(string: "https://example.com")!) { data, response, error in
    // ...
}.resume()
```
