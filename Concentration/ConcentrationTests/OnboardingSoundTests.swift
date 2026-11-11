import SwiftUI
import UIKit
import XCTest
@testable import Concentration

@MainActor
final class OnboardingSoundTests: XCTestCase {
    func testShowingFirstTipNotifiesOnce() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        var notifications = 0
        window.rootViewController = UIHostingController(
            rootView: OnboardingView(
                appName: "Concentration",
                features: [OBFeature(title: "Tip", description: "Test tip")],
                onShowTip: { notifications += 1 }
            )
        )
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(notifications, 1)
    }

    func testEmptyJourneyDoesNotNotify() async throws {
        let scene = try XCTUnwrap(
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        )
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        var notifications = 0
        window.rootViewController = UIHostingController(
            rootView: OnboardingView(
                appName: "Concentration",
                features: [],
                onShowTip: { notifications += 1 }
            )
        )
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            previousWindow?.makeKeyAndVisible()
        }

        try await Task.sleep(for: .milliseconds(200))
        XCTAssertEqual(notifications, 0)
    }
}
