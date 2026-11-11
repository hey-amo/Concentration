import Foundation
import XCTest
@testable import Concentration

@MainActor
final class OnboardingSoundTests: XCTestCase {
    func testMultiStepJourneyNotifiesOncePerPresentation() throws {
        let suite = "OnboardingSoundTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var notifications = 0
        let coordinator = OnboardingCoordinator(defaults: defaults) { notifications += 1 }

        coordinator.dealCompleted()
        coordinator.presentIfPossible(false)
        XCTAssertEqual(notifications, 0)
        coordinator.presentIfPossible(true)
        XCTAssertEqual(coordinator.activeJourney, .firstPlay)
        XCTAssertGreaterThan(OnboardingJourney.firstPlay.features.count, 1)
        coordinator.presentIfPossible(true)
        XCTAssertEqual(notifications, 1)

        coordinator.suspendForAnimation()
        coordinator.presentIfPossible(true)
        XCTAssertEqual(notifications, 1)
        coordinator.finishJourney()
        coordinator.replayIntroduction()
        coordinator.presentIfPossible(true)
        XCTAssertEqual(notifications, 2)
    }

    func testDisabledTipsNeverNotify() throws {
        let suite = "OnboardingSoundTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var notifications = 0
        let coordinator = OnboardingCoordinator(defaults: defaults) { notifications += 1 }
        coordinator.setTipsEnabled(false)
        coordinator.dealCompleted()
        coordinator.replayIntroduction()
        coordinator.gameEventOccurred(.match)
        coordinator.presentIfPossible(true)
        XCTAssertNil(coordinator.activeJourney)
        XCTAssertEqual(notifications, 0)
    }
}
