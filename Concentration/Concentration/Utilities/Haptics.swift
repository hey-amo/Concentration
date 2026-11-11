import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class HapticsController: GameEventObserving {
    func gameEventOccurred(_ event: GameEvent) {
        guard event == .mismatch else { return }

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #elseif canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        #endif
    }
}
