import XCTest

/// Stages a believable family evening in the real app and captures the App
/// Store screenshot set as keep-always attachments, numbered in the order
/// they should appear on the store page.
///
/// Run via `scripts/capture-screenshots.sh` (fresh install + clean status bar
/// + attachment export). Not part of the CI `Fable` scheme on purpose: this
/// is a capture lane, not a regression test.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        // Fable+ so the series feature — a headline of the store page — is
        // stageable. The paywall itself is deliberately not a screenshot.
        app.launchArguments = ["-fable-debug-plus"]
        app.launch()

        // ── First run: who are tonight's stories for? ──────────────────────
        let nameField = app.textFields["Their name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 15),
                      "expected the first-run setup screen on a fresh install")
        nameField.tap()
        nameField.typeText("Nora")

        app.buttons["4–6 years"].tap()

        let companionField = app.textFields[
            "A favorite friend or animal — skip it and a small brave fox steps in"]
        companionField.tap()
        companionField.typeText("Pip the penguin")

        let comfortField = app.textFields["Something cozy they sleep with — optional too"]
        comfortField.tap()
        comfortField.typeText("the star blanket")
        comfortField.typeText("\n") // .done — drops the keyboard for the shot
        settle()

        snap("05-setup")

        app.buttons["Begin the first story"].tap()

        // ── Tonight: the first story ───────────────────────────────────────
        let tellButton = app.buttons["Tell tonight's story"]
        XCTAssertTrue(tellButton.waitForExistence(timeout: 15))
        tellButton.tap()

        openReader(app)
        snap("01-reader-title")

        app.swipeLeft() // onto the first story page
        settle()
        snap("03-reader-page")

        // ── The end page: moral, sweet dreams, and the series invitation ──
        turnToLastPage(app)
        let makeSeries = app.buttons["Make this a continuing adventure"]
        if !makeSeries.isHittable {
            app.swipeUp()
            settle()
        }
        snap("04-reader-end")

        makeSeries.tap()
        settle()
        app.buttons["Close the storybook"].tap()

        // ── Two more stories so the storybook looks lived-in ──────────────
        for theme in ["Ocean", "Magic"] {
            XCTAssertTrue(tellButton.waitForExistence(timeout: 15))
            app.buttons[theme].tap()
            tellButton.tap()
            openReader(app)
            app.navigationBars.buttons.firstMatch.tap() // back — story is saved
        }

        // ── Tonight, now with an adventure to continue ────────────────────
        XCTAssertTrue(tellButton.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Episode 2 tonight"].waitForExistence(timeout: 5),
                      "expected the continuing-adventure card on Tonight")
        snap("02-tonight")

        // ── The storybook ─────────────────────────────────────────────────
        app.buttons["Storybook"].tap()
        XCTAssertTrue(app.navigationBars["Storybook"].waitForExistence(timeout: 10))
        settle()
        snap("06-library")
    }

    // MARK: - Helpers

    /// Waits out story generation (curated is near-instant; the on-device
    /// model takes seconds) until the reader's title page is up.
    @MainActor
    private func openReader(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["A story for Nora"].waitForExistence(timeout: 120),
                      "expected the reader title page after generation")
        settle()
    }

    /// Turns pages until "The End" is on the last page. Stories cap out well
    /// under a dozen pages; the bound is a hang guard, not an expectation.
    @MainActor
    private func turnToLastPage(_ app: XCUIApplication) {
        var turns = 0
        while !app.staticTexts["The End"].exists && turns < 12 {
            app.swipeLeft()
            turns += 1
            settle()
        }
        XCTAssertTrue(app.staticTexts["The End"].exists, "never reached the last page")
    }

    /// Full-screen capture (status bar included — ASC wants the real frame).
    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Lets springy UI (page turns, keyboard, crossfades) come to rest so
    /// captures aren't mid-animation.
    private func settle() {
        Thread.sleep(forTimeInterval: 0.8)
    }
}
