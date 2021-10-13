import XCTest
@testable import BlueTriangle

final class BlueTriangleTests: XCTestCase {

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
