import Foundation
import Observation

@MainActor
@Observable
final class OnboardingCoordinator: GameEventObserving {
    static let tipsEnabledKey = "showOnboardingTips"
    private static let completedKey = "completedOnboardingJourneys"

    private(set) var activeJourney: OnboardingJourney?
    private(set) var pendingJourneys: [OnboardingJourney] = []
    private(set) var tipsEnabled: Bool
    private(set) var requestRevision = 0

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let eventObserver: (any GameEventObserving)?
    @ObservationIgnored private let playNotification: () -> Void
    @ObservationIgnored private var completed: Set<String>
    @ObservationIgnored private var notifiedJourney: OnboardingJourney?

    init(
        defaults: UserDefaults = .standard,
        eventObserver: (any GameEventObserving)? = nil,
        playNotification: @escaping () -> Void = { AudioManager.shared.play(.tipNotification) }
    ) {
        self.defaults = defaults
        self.eventObserver = eventObserver
        self.playNotification = playNotification
        tipsEnabled = defaults.object(forKey: Self.tipsEnabledKey) == nil
            ? true : defaults.bool(forKey: Self.tipsEnabledKey)
        completed = Set(defaults.stringArray(forKey: Self.completedKey) ?? [])
    }

    func setTipsEnabled(_ enabled: Bool) {
        tipsEnabled = enabled
        defaults.set(enabled, forKey: Self.tipsEnabledKey)
        if !enabled {
            activeJourney = nil
            pendingJourneys.removeAll()
            notifiedJourney = nil
        }
    }

    func dealCompleted() {
        enqueue(.firstPlay)
    }

    func replayIntroduction() {
        guard tipsEnabled else { return }
        pendingJourneys.removeAll { $0 == .firstPlay }
        pendingJourneys.insert(.firstPlay, at: 0)
        requestRevision &+= 1
    }

    func gameEventOccurred(_ event: GameEvent) {
        eventObserver?.gameEventOccurred(event)
        switch event {
        case .match: enqueue(.firstMatch)
        case .mismatch: enqueue(.firstMismatch)
        case .win:
            pendingJourneys.removeAll { $0 == .firstMatch || $0 == .firstMismatch }
            enqueue(.puzzleComplete)
        case .loss:
            pendingJourneys.removeAll { $0 == .firstMatch || $0 == .firstMismatch }
            enqueue(.timeOut)
        }
    }

    func newGame() {
        activeJourney = nil
        pendingJourneys.removeAll()
        notifiedJourney = nil
        requestRevision &+= 1
    }

    func presentIfPossible(_ canPresent: Bool) {
        guard canPresent, tipsEnabled, activeJourney == nil, !pendingJourneys.isEmpty else { return }
        let journey = pendingJourneys.removeFirst()
        guard !journey.features.isEmpty else { return }
        activeJourney = journey
        if notifiedJourney != journey {
            notifiedJourney = journey
            playNotification()
        }
    }

    func suspendForAnimation() {
        guard let journey = activeJourney else { return }
        activeJourney = nil
        pendingJourneys.insert(journey, at: 0)
    }

    func finishJourney() {
        guard let journey = activeJourney else { return }
        completed.insert(journey.rawValue)
        defaults.set(Array(completed).sorted(), forKey: Self.completedKey)
        activeJourney = nil
        notifiedJourney = nil
        requestRevision &+= 1
    }

    private func enqueue(_ journey: OnboardingJourney) {
        guard tipsEnabled, !completed.contains(journey.rawValue),
              activeJourney != journey, !pendingJourneys.contains(journey) else { return }
        pendingJourneys.append(journey)
        requestRevision &+= 1
    }
}
