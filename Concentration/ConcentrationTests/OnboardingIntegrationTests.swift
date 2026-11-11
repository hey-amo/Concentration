import SwiftUI
import UIKit
import XCTest
@testable import Concentration

@MainActor
final class OnboardingIntegrationTests: XCTestCase {
    func testMismatchWaitsForCardAnimationAndPausesTimer() async throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "This test requires animations.")
        let suite = "OnboardingIntegrationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = OnboardingCoordinator(defaults: defaults, playNotification: {})
        let firstPairID = UUID()
        let secondPairID = UUID()
        let cards = [
            Card(character: .dog, pairId: firstPairID, position: 0),
            Card(character: .dog, pairId: firstPairID, position: 1),
            Card(character: .cat, pairId: secondPairID, position: 2),
            Card(character: .cat, pairId: secondPairID, position: 3)
        ]
        let game = GameState(cards: cards, timeLimit: 20, eventObserver: coordinator)
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(
            rootView: GameView(onboarding: coordinator, gameState: game)
                .environment(\.scenePhase, .active)
        )
        window.makeKeyAndVisible()
        defer {
            game.pauseTimer()
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        let introDeadline = ContinuousClock.now + .seconds(8)
        while coordinator.activeJourney == nil && ContinuousClock.now < introDeadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertEqual(coordinator.activeJourney, .firstPlay)
        coordinator.finishJourney()
        try await Task.sleep(for: .milliseconds(100))

        await game.selectCard(cards[0].id)
        await game.selectCard(cards[2].id)
        XCTAssertGreaterThan(game.activeCardAnimations, 0)
        XCTAssertNil(coordinator.activeJourney)

        let tipDeadline = ContinuousClock.now + .seconds(5)
        while coordinator.activeJourney == nil && ContinuousClock.now < tipDeadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertEqual(coordinator.activeJourney, .firstMismatch)
        XCTAssertEqual(game.activeCardAnimations, 0)
        let pausedTime = game.timeRemaining
        try await Task.sleep(for: .milliseconds(1_200))
        XCTAssertEqual(game.timeRemaining, pausedTime)
        coordinator.finishJourney()
        try await Task.sleep(for: .milliseconds(1_200))
        XCTAssertLessThan(game.timeRemaining, pausedTime)
    }
}
