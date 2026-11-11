import SwiftUI
import UIKit
import XCTest
@testable import Concentration

@MainActor
final class GameBoardAnimationTests: XCTestCase {
    func testDealCompletionWaitsForStaggeredCardAnimations() async throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "This test requires animations.")
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let game = GameState()
        var completions = 0
        window.rootViewController = UIHostingController(
            rootView: GameBoardView(
                cards: game.cards,
                isReady: false,
                onSelect: { _ in XCTFail("Cards must not be selectable during the deal.") },
                onDealComplete: { completions += 1 }
            )
        )
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        try await Task.sleep(for: .milliseconds(850))
        XCTAssertEqual(completions, 0, "The staggered deal should still be running.")

        let deadline = ContinuousClock.now + .seconds(5)
        while completions == 0 && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertEqual(completions, 1)
    }

    func testRemovedBoardDoesNotCompleteItsDeal() async throws {
        try XCTSkipIf(UIAccessibility.isReduceMotionEnabled, "This test requires animations.")
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        var completions = 0
        window.rootViewController = UIHostingController(
            rootView: GameBoardView(
                cards: GameState().cards,
                isReady: false,
                onSelect: { _ in XCTFail("Cards must not be selectable during the deal.") },
                onDealComplete: { completions += 1 }
            )
        )
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        try await Task.sleep(for: .milliseconds(850))
        window.rootViewController = nil
        try await Task.sleep(for: .seconds(3))
        XCTAssertEqual(completions, 0)
    }
}
