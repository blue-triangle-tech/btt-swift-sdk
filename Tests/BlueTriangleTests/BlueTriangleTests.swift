import XCTest
import Combine
@testable import BlueTriangle

final class BlueTriangleTests: XCTestCase {

    static var uploaderQueue: DispatchQueue = Mock.uploaderQueue
    static var onSendRequest: (Request) -> Void = { _ in }

    override class func setUp() {
        super.setUp()
        BlueTriangle.configure { configuration in
            configuration.uploaderConfiguration = Mock.makeUploaderConfiguration(queue: uploaderQueue) { request in
                onSendRequest(request)
            }
        }
        BlueTriangle.prime()
        BlueTriangle.reset()
    }
    
    override func tearDown() {
        Self.onSendRequest = { _ in }
        BlueTriangle.reset()
        super.tearDown()
    }

    func testOSInfo() {
        let os = Device.os
        let osVersion = Device.osVersion

        #if os(iOS)
        XCTAssertEqual(os, "iOS")
        #elseif os(tvOS)
        XCTAssertEqual(os, "tvOS")
        #elseif os(watchOS)
        XCTAssertEqual(os, "watchOS")
        #elseif os(macOS)
        XCTAssertEqual(os, "macOS")
        #endif

        XCTAssertFalse(osVersion.isEmpty)
    }
}
