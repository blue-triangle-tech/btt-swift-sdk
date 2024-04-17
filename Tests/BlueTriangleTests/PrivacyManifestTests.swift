//
//  PrivacyManifestTests.swift
//  
//
//  Created by Ashok Singh on 05/04/24.
//

import XCTest
import BlueTriangle

final class PrivacyManifestTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
   /* public static func findFileInBundle(fileName: String) -> String? {
        let bundle = Bundle(identifier: "blue-triangle_BlueTriangle.bundle")
        let bundleID = bundle?.path(forResource: "PrivacyInfo", ofType: nil)
        print("Bundle Identifier : \(bundle?.bundleIdentifier) - \(bundleID)")
        if let filePath = bundle?.path(forResource: fileName, ofType: nil) {
            print("Bundle Path: \(filePath)")
        }
        let allBundles = Bundle.allBundles
        for bundle in allBundles {
       
            print("Bundle Identifier : \(bundle.bundleIdentifier)")

            let path = bundle.path(forResource: fileName, ofType: nil)
            print("Bundle Path :\(path)")
            
            if let filePath = bundle.path(forResource: fileName, ofType: nil) {
                return filePath
            }
        }
        return nil
    }
    
    func testPrivacyInfoFile() {
        // Name of the file you want to check
        
        let path = PrivacyManifestTests.findFileInBundle(fileName: "PrivacyInfo.xcprivacy")
                
        print("Bundle Path: \(path)")
        
        let fileName = "DeviceTests.swift" //"PrivacyInfo.xcprivacy"
        let allBundles = Bundle.allBundles
        for bundle in allBundles {
            let url = bundle.url(forResource: "BlueTriangleTests", withExtension: "swift")
            print("Bundle URL: \(url)")
            if let bundleIdentifier = bundle.path(forResource: fileName, ofType: nil) {
                print("Bundle Identifier: \(bundleIdentifier)")
            }
        }
        //All bundle array
        //find resource
        // Get the path of the file in the app's bundle
       /* if let filePath = Bundle.main.path(forResource: fileName, ofType: "swift") {
            // File exists in the bundle
            XCTAssertTrue(true, "File exists in the bundle: \(fileName)")
        } else {
            // File does not exist in the bundle
            XCTFail("File does not exist in the bundle: \(fileName)")
        }*/
    }*/
}
