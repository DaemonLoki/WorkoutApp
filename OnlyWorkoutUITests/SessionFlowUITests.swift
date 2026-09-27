import XCTest

/// The core Session flow end to end (README §16, M1): start the Next Up Workout, log every Set,
/// accept the Step Up offered after a Target Hit, and finish on the Summary.
@MainActor
final class SessionFlowUITests: XCTestCase {
    override func setUp() async throws {
        continueAfterFailure = false
    }

    func testFullSessionWithStepUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        addUIInterruptionMonitor(withDescription: "Notifications") { alert in
            alert.buttons.element(boundBy: 1).tap()
            return true
        }

        app.buttons["startSessionButton"].tap()
        snapshot(app, "1-set")

        // Bench Press, 2 × 8 @ 60 kg: log both Sets at their prefilled values.
        let done = app.buttons["doneButton"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let skipRest = app.buttons["skipRestButton"]
        XCTAssertTrue(skipRest.waitForExistence(timeout: 5))
        snapshot(app, "2-rest")
        skipRest.tap()
        done.tap()

        // Every planned Set hit its Target, so a Step Up is offered.
        let accept = app.buttons["acceptOfferButton"]
        XCTAssertTrue(accept.waitForExistence(timeout: 5))
        snapshot(app, "3-step-up")
        accept.tap()
        skipRest.tap()

        // Triceps Pushdown, 1 × 12.
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()
        let decline = app.buttons["declineOfferButton"]
        if decline.waitForExistence(timeout: 2) { decline.tap() }

        let finish = app.buttons["finishSessionButton"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()

        let summaryDone = app.buttons["summaryDoneButton"]
        XCTAssertTrue(summaryDone.waitForExistence(timeout: 5))
        sleep(2)
        snapshot(app, "4-summary")
        summaryDone.tap()

        // Back on Today with the declined Pushdown Step Up waiting.
        XCTAssertTrue(app.buttons["startSessionButton"].waitForExistence(timeout: 5))
        snapshot(app, "5-today-after")

        // The finished Session shows up in Progress.
        app.buttons["Progress"].tap()
        let benchRow = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Bench Press'")).firstMatch
        XCTAssertTrue(benchRow.waitForExistence(timeout: 5))
        snapshot(app, "6-progress")
        benchRow.tap()
        sleep(1)
        snapshot(app, "7-exercise-progress")
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
