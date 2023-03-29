//
//  CrashReportManagerTests.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class CrashReportManagerTests: XCTestCase {
    let crashErrorReport = ErrorReport(message: "crash_message", line: 1, column: 2, time: 100)

    var crashReport: CrashReport {
        .init(sessionID: 100_000_000_000_000_001, report: crashErrorReport)
    }

    override func tearDown() {
        super.tearDown()
        CrashReportPersistenceMock.reset()
    }

    func testReportClearedAfterUpload() {
        let reportReadExpectation = expectation(description: "Crash report read")
        let reportClearedExpectation = expectation(description: "Crash report cleared")
        CrashReportPersistenceMock.configure(
            onRead: {
                reportReadExpectation.fulfill()
                return self.crashReport
            },
            onClear: { reportClearedExpectation.fulfill() })

        let sut = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: UploaderMock(),
            sessionProvider: { Mock.session }
        )

        sut.uploadCrashReport(session: Mock.session)
        wait(for: [reportReadExpectation, reportClearedExpectation], timeout: 1.0)
    }

    func testCrashTimerUploaded() throws {
        CrashReportPersistenceMock.configure(
            onRead: { self.crashReport },
            onClear: {})

        var timerRequest: Request!
        let uploadExpectation = expectation(description: "Timer uploaded")
        let uploader = UploaderMock { request in
            if timerRequest == nil {
                timerRequest = request
                uploadExpectation.fulfill()
            }
        }

        let sut = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: uploader,
            sessionProvider: { Mock.session }
        )

        sut.uploadCrashReport(session: Mock.session)
        wait(for: [uploadExpectation], timeout: 1.0)

        let actualTimer = try JSONDecoder().decode(TimerRequest.self, from: timerRequest.body!.base64DecodedData()!)
        XCTAssertEqual(actualTimer.session.sessionID, crashReport.sessionID)
        XCTAssertEqual(actualTimer.timer.startTime, crashErrorReport.time)
    }

    func testCrashReportUploaded() throws {
        CrashReportPersistenceMock.configure(
            onRead: { self.crashReport },
            onClear: {})

        var requestCount = 0
        var errorRequest: Request!
        let uploadExpectation = expectation(description: "Report uploaded")
        let uploader = UploaderMock { request in
            requestCount += 1
            if requestCount > 1 {
                errorRequest = request
                uploadExpectation.fulfill()
            }
        }

        let sut = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: uploader,
            sessionProvider: { Mock.session }
        )

        sut.uploadCrashReport(session: Mock.session)
        wait(for: [uploadExpectation], timeout: 1.0)

        let actualReport = try JSONDecoder().decode([ErrorReport].self,from: errorRequest.body!.base64DecodedData()!).first!

        XCTAssertEqual(errorRequest.parameters!["nStart"], "\(crashErrorReport.time)")
        XCTAssertEqual(errorRequest.parameters!["sessionID"], "\(crashReport.sessionID)")

        XCTAssertEqual(actualReport.message, crashErrorReport.message)
        XCTAssertEqual(actualReport.time, crashErrorReport.time)
    }
}
