import XCTest

/// Stages a believable family evening in the real app and captures every
/// scene as keep-always attachments.
///
/// Run via `scripts/capture-screenshots.sh`, which fresh-installs, cleans the
/// status bar, and repeats the whole lane once per supported language. Not
/// part of the CI `Fable` scheme on purpose: this is a capture lane, not a
/// regression test.
///
/// Every element is found by accessibility IDENTIFIER, never by visible text,
/// because the same lane runs in seven languages. Adding a scene here means
/// adding an identifier in the view, not a translated string here.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAppStoreScreenshots() throws {
        let app = XCUIApplication()
        // Fable+ so the series feature is stageable.
        app.launchArguments = ["-fable-debug-plus"]
        app.launch()

        // ── First run: who are tonight's stories for? ──────────────────────
        let nameField = app.textFields["field.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 20),
                      "expected the first-run setup screen on a fresh install")
        nameField.tap()
        nameField.typeText("Nora")

        let companionField = app.textFields["field.companion"]
        companionField.tap()
        companionField.typeText("Pip")

        // The comfort object is left EMPTY on purpose: the app then weaves in
        // its own localized default ("uma cobertinha macia e quentinha" in
        // pt-BR, "et mykt og varmt teppe" in bokmål), so the captured prose is
        // fully in the language being reviewed instead of carrying an English
        // fragment the tester happened to type.
        let comfortField = app.textFields["field.comfort"]
        comfortField.tap()
        comfortField.typeText("\n") // .done with nothing typed: keyboard away, slot empty
        settle()
        snap("05-setup")

        app.buttons["button.primary"].tap()

        // ── Tonight: the first story ───────────────────────────────────────
        let tellButton = app.buttons["button.tellStory"]
        XCTAssertTrue(tellButton.waitForExistence(timeout: 20))
        snap("07-tonight-first-run")
        tellButton.tap()

        openReader(app)
        snap("01-reader-title")

        app.swipeLeft() // onto the first story page
        settle()
        snap("03-reader-page")

        // ── The end page: moral, sweet dreams, series invitation ──────────
        turnToLastPage(app)
        let makeSeries = app.buttons["button.makeSeries"]
        if makeSeries.exists, !makeSeries.isHittable {
            app.swipeUp()
            settle()
        }
        snap("04-reader-end")

        if makeSeries.exists { makeSeries.tap() }
        settle()
        app.buttons["button.closeStorybook"].tap()

        // ── Two more stories so the storybook looks lived-in ──────────────
        for theme in ["ocean", "magic"] {
            XCTAssertTrue(tellButton.waitForExistence(timeout: 20))
            let card = app.buttons["theme.\(theme)"]
            if card.exists { card.tap() }
            tellButton.tap()
            openReader(app)
            app.navigationBars.buttons.firstMatch.tap() // back — story is saved
        }

        // ── Tonight, now with an adventure to continue ────────────────────
        XCTAssertTrue(tellButton.waitForExistence(timeout: 20))
        settle()
        snap("02-tonight")

        // ── The storybook ─────────────────────────────────────────────────
        app.buttons["button.storybook"].tap()
        XCTAssertTrue(app.buttons["button.storybook"].waitForNonExistence(timeout: 10)
                      || app.staticTexts.count > 0)
        settle()
        snap("06-library")
        app.navigationBars.buttons.firstMatch.tap()

        // ── Settings, still as a subscriber ───────────────────────────────
        let settingsButton = app.buttons["button.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
        XCTAssertTrue(app.otherElements["settings.root"].waitForExistence(timeout: 10)
                      || app.scrollViews.firstMatch.waitForExistence(timeout: 10))
        settle()
        snap("08-settings")
        app.swipeDown(velocity: .fast) // dismiss the sheet
        settle()

        // ── The paywall, which only a free family can see ─────────────────
        app.terminate()
        app.launchArguments = [] // no debug entitlement this time
        app.launch()

        let menu = app.buttons["menu.profile"]
        XCTAssertTrue(menu.waitForExistence(timeout: 20))
        menu.tap()
        settle()
        let addChild = app.buttons["menu.addChild"]
        XCTAssertTrue(addChild.waitForExistence(timeout: 10),
                      "expected the profile menu to offer adding a child")
        addChild.tap()
        XCTAssertTrue(app.otherElements["paywall.root"].waitForExistence(timeout: 15)
                      || app.scrollViews.firstMatch.waitForExistence(timeout: 15))
        settle()
        settle()
        snap("09-paywall")
    }

    // MARK: - Helpers

    /// Waits out story generation (curated is near-instant; the on-device
    /// model takes seconds) until the reader's title page is up.
    @MainActor
    private func openReader(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["reader.titlePage"].waitForExistence(timeout: 180),
                      "expected the reader title page after generation")
        settle()
    }

    /// Turns pages until the last one is reached. Stories cap out well under a
    /// dozen pages; the bound is a hang guard, not an expectation.
    @MainActor
    private func turnToLastPage(_ app: XCUIApplication) {
        var turns = 0
        while !app.staticTexts["reader.theEnd"].exists && turns < 14 {
            app.swipeLeft()
            turns += 1
            settle()
        }
        XCTAssertTrue(app.staticTexts["reader.theEnd"].exists, "never reached the last page")
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
        Thread.sleep(forTimeInterval: 0.9)
    }
}
