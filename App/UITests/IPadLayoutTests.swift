import XCTest

/// Walks the core evening on an iPad, rotating between orientations, and
/// captures each scene. The reading-column layout is orientation-agnostic
/// by construction; this lane proves it on a real device size and will
/// later double as the ASC iPad screenshot capture.
///
/// Run manually against an iPad simulator (not part of CI's `Fable`
/// scheme, like the other capture lanes):
///   xcodebuild -project Fable.xcodeproj -scheme FableScreenshots \
///     -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test \
///     -only-testing FableScreenshots/IPadLayoutTests
final class IPadLayoutTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEveningInBothOrientations() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-fable-debug-plus"]
        app.launch()

        // Fresh install shows setup; a seeded device skips straight to
        // Tonight. Handle both so the lane runs on any simulator state.
        let nameField = app.textFields["field.name"]
        if nameField.waitForExistence(timeout: 10) {
            nameField.tap()
            nameField.typeText("Nova\n")
            app.buttons["button.primary"].tap()
        }

        let tellButton = app.buttons["button.tellStory"]
        XCTAssertTrue(tellButton.waitForExistence(timeout: 20))
        settle()
        snap("ipad-tonight-portrait")

        XCUIDevice.shared.orientation = .landscapeLeft
        settle()
        XCTAssertTrue(tellButton.isHittable, "the tell button must survive rotation")
        snap("ipad-tonight-landscape")

        tellButton.tap()
        XCTAssertTrue(app.staticTexts["reader.titlePage"].waitForExistence(timeout: 180),
                      "expected the reader title page after generation")
        settle()
        snap("ipad-reader-title-landscape")

        app.swipeLeft()
        settle()
        snap("ipad-reader-page-landscape")

        XCUIDevice.shared.orientation = .portrait
        settle()
        XCTAssertTrue(app.staticTexts.firstMatch.exists)
        snap("ipad-reader-page-portrait")
    }

    // MARK: - Helpers (same shape as ScreenshotTests)

    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func settle() {
        Thread.sleep(forTimeInterval: 0.9)
    }
}
