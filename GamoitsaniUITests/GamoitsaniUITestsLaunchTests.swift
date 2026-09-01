//
//  GamoitsaniUITestsLaunchTests.swift
//  GamoitsaniUITests
//
//  Created by Daviti Khvedelidze on 22/04/2024.
//

import XCTest

final class GamoitsaniUITestsLaunchTests: XCTestCase {

    // Left at the default (false) deliberately. The Xcode template sets this to `true`,
    // which reruns testLaunch() once per target application UI configuration — on this
    // app that is 128 launches, each attaching a full-resolution screenshot below. A
    // single `xcodebuild test` ran for over ten minutes and wrote ~4 GB of result
    // bundles before filling the disk. One launch is enough for a smoke test.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10), "app did not reach the foreground")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        // deleteOnSuccess, not keepAlways: a kept screenshot per run is what made the
        // result bundles unbounded. On failure the screenshot is still retained.
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
}
