//
//  ConcentrationUITests.swift
//  ConcentrationUITests
//
//  Created by Amarjit on 01/11/2025.
//

import XCTest

final class ConcentrationUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testNewGameConfirmationCancelsOrResetsProgress() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-showOnboardingTips", "NO"]
        app.launch()

        let firstCard = app.buttons["card-0"]
        XCTAssertTrue(firstCard.waitForExistence(timeout: 10))
        let ready = expectation(
            for: NSPredicate(format: "isEnabled == true AND isHittable == true"),
            evaluatedWith: firstCard
        )
        wait(for: [ready], timeout: 10)
        firstCard.tap()
        XCTAssertTrue(app.staticTexts["Flips: 1"].waitForExistence(timeout: 2))
        let footerFrame = app.buttons["New Game"].frame
        app.buttons["Settings"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Flips: 1"].exists)
        XCTAssertTrue(app.buttons["card-1"].isHittable)

        app.buttons["New Game"].tap()
        let alert = app.alerts["Start a New Game?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        XCTAssertTrue(alert.staticTexts["Your current game progress will be lost."].exists)
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Flips: 1"].exists)

        app.buttons["New Game"].tap()
        alert.buttons["Start New Game"].tap()
        XCTAssertTrue(app.staticTexts["Flips: 0"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Score: 0"].exists)
        let newGameButton = app.buttons["New Game"]
        let newGameReady = expectation(
            for: NSPredicate(format: "isEnabled == true AND isHittable == true"),
            evaluatedWith: newGameButton
        )
        wait(for: [newGameReady], timeout: 10)
        XCTAssertEqual(newGameButton.frame.minY, footerFrame.minY, accuracy: 1)
        XCTAssertTrue(app.buttons["Settings"].isHittable)
        XCTAssertTrue(app.buttons["card-0"].isHittable)
        app.buttons["card-0"].tap()
        XCTAssertTrue(app.staticTexts["Flips: 1"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testIntroductionBlocksGameUntilFinishedAndCanBeReplayed() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-showOnboardingTips", "YES", "-completedOnboardingJourneys", "()"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Find a Pair"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["card-0"].isHittable)
        XCTAssertFalse(app.buttons["Settings"].isHittable)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Watch the Clock"].exists)
        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Match Them All"].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["card-0"].waitForExistence(timeout: 3))
        app.buttons["Settings"].tap()
        app.buttons["Replay introduction"].tap()
        XCTAssertTrue(app.staticTexts["Find a Pair"].waitForExistence(timeout: 5))
        app.buttons["Skip"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 3))
        app.buttons["Settings"].tap()
        app.switches["Show tips"].coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        XCTAssertFalse(app.buttons["Replay introduction"].isEnabled)
        app.buttons["Done"].tap()
        app.buttons["New Game"].tap()
        app.alerts["Start a New Game?"].buttons["Start New Game"].tap()
        let ready = expectation(
            for: NSPredicate(format: "isEnabled == true AND isHittable == true"),
            evaluatedWith: app.buttons["New Game"]
        )
        wait(for: [ready], timeout: 10)
        XCTAssertFalse(app.staticTexts["Find a Pair"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
