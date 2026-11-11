import Foundation
import XCTest
@testable import Concentration

@MainActor
final class OnboardingCoordinatorTests: XCTestCase {
    func testCompletionAndSettingsPersistAcrossCoordinatorInstances() throws {
        let suite = "OnboardingCoordinatorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = OnboardingCoordinator(defaults: defaults, playNotification: {})
        XCTAssertTrue(coordinator.tipsEnabled)
        coordinator.dealCompleted()
        coordinator.presentIfPossible(true)
        coordinator.finishJourney()
        coordinator.setTipsEnabled(false)

        let restored = OnboardingCoordinator(defaults: defaults, playNotification: {})
        XCTAssertFalse(restored.tipsEnabled)
        restored.setTipsEnabled(true)
        restored.dealCompleted()
        XCTAssertTrue(restored.pendingJourneys.isEmpty)
        restored.replayIntroduction()
        restored.presentIfPossible(true)
        XCTAssertEqual(restored.activeJourney, .firstPlay)
    }

    func testFinalMatchIsReplacedByWinAndNewGameClearsPendingEvents() throws {
        let suite = "OnboardingCoordinatorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = OnboardingCoordinator(defaults: defaults, playNotification: {})
        coordinator.gameEventOccurred(.match)
        coordinator.gameEventOccurred(.win)
        XCTAssertEqual(coordinator.pendingJourneys, [.puzzleComplete])
        coordinator.newGame()
        XCTAssertTrue(coordinator.pendingJourneys.isEmpty)
        coordinator.gameEventOccurred(.mismatch)
        coordinator.gameEventOccurred(.loss)
        XCTAssertEqual(coordinator.pendingJourneys, [.timeOut])
    }

    func testTurningTipsOffDismissesAndDiscardsPending() throws {
        let suite = "OnboardingCoordinatorTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = OnboardingCoordinator(defaults: defaults, playNotification: {})
        coordinator.dealCompleted()
        coordinator.presentIfPossible(true)
        coordinator.gameEventOccurred(.mismatch)
        coordinator.setTipsEnabled(false)
        XCTAssertNil(coordinator.activeJourney)
        XCTAssertTrue(coordinator.pendingJourneys.isEmpty)
        coordinator.setTipsEnabled(true)
        coordinator.presentIfPossible(true)
        XCTAssertNil(coordinator.activeJourney)
    }
}
