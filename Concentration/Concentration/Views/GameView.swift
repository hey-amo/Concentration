import SwiftUI

struct GameView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @State private var gameState: GameState
    @State private var onboarding: OnboardingCoordinator
    @State private var showSettings = false
    @State private var settingsVisible = false
    @State private var confirmNewGame = false
    @State private var dealID = UUID()
    @State private var isDealComplete = false
    @State private var hasCompletedInitialDeal = false
    @State private var footerAnimating = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var gameFocused: Bool

    init() {
        let coordinator = OnboardingCoordinator(eventObserver: HapticsController())
        _onboarding = State(initialValue: coordinator)
        _gameState = State(initialValue: GameState(eventObserver: coordinator))
    }

    init(onboarding: OnboardingCoordinator, gameState: GameState) {
        _onboarding = State(initialValue: onboarding)
        _gameState = State(initialValue: gameState)
    }

    private struct PresentationState: Equatable {
        let sceneActive: Bool
        let animationsPlaying: Bool
        let canPresent: Bool
        let requestRevision: Int
        let tipsEnabled: Bool
    }

    private var presentationState: PresentationState {
        let animationsPlaying = !isDealComplete || footerAnimating || gameState.activeCardAnimations > 0
        return PresentationState(
            sceneActive: scenePhase == .active,
            animationsPlaying: animationsPlaying,
            canPresent: scenePhase == .active && !animationsPlaying
                && !gameState.isResolvingTurn && !settingsVisible && !confirmNewGame,
            requestRevision: onboarding.requestRevision,
            tipsEnabled: onboarding.tipsEnabled
        )
    }

    private var onboardingBlocksInteraction: Bool {
        onboarding.activeJourney?.blocksGameInteraction == true
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    GameScoreView(gameState: gameState)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityFocused($gameFocused)
                    GameTimerView(gameState: gameState)
                }
                .padding(.horizontal)

                GameBoardView(
                    cards: gameState.cards,
                    isReady: isDealComplete,
                    onSelect: { cardID in
                        guard isDealComplete else { return }
                        Task { await gameState.selectCard(cardID, animated: !reduceMotion) }
                    },
                    onDealComplete: {
                        finishDeal()
                    }
                )
                .id(dealID)

                // Footer bar
                GameFooterView(
                    isDealComplete: isDealComplete,
                    hasCompletedInitialDeal: hasCompletedInitialDeal,
                    onNewGame: {
                        confirmNewGame = true
                    },
                    onSettings: {
                        settingsVisible = true
                        showSettings = true
                    }
                )
            }
            .padding(.vertical)
            .allowsHitTesting(!onboardingBlocksInteraction)
            .accessibilityHidden(onboardingBlocksInteraction)

            GameResultOverlay(gameState: gameState, onPlayAgain: startNewGame)
                .allowsHitTesting(!onboardingBlocksInteraction)
                .accessibilityHidden(onboardingBlocksInteraction)

            if let journey = onboarding.activeJourney {
                if journey.blocksGameInteraction {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)

                    GeometryReader { geometry in
                        ScrollView {
                            tipCard(journey)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: geometry.size.height)
                        }
                    }
                    .zIndex(1)
                } else {
                    VStack {
                        tipCard(journey)
                        Spacer()
                    }
                    .zIndex(1)
                }
            }
        }
        .preferredColorScheme(AppAppearance(rawValue: appearanceMode)?.colorScheme)
        .sheet(isPresented: $showSettings, onDismiss: { settingsVisible = false }) {
            SettingsView(onboarding: onboarding) {
                onboarding.replayIntroduction()
                showSettings = false
            }
        }
        .alert("Start a New Game?", isPresented: $confirmNewGame) {
            Button("Start New Game", role: .destructive, action: startNewGame)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current game progress will be lost.")
        }
        .task(id: presentationState) {
            reconcilePresentation()
        }
    }

    private func tipCard(_ journey: OnboardingJourney) -> some View {
        OnboardingView(
            appName: "Concentration",
            features: journey.features,
            onFinish: {
                onboarding.finishJourney()
                if journey.blocksGameInteraction {
                    gameFocused = true
                }
            }
        )
        .padding()
        .id(journey)
    }

    private func reconcilePresentation() {
        let animationsPlaying = !isDealComplete || footerAnimating || gameState.activeCardAnimations > 0
        if animationsPlaying {
            onboarding.suspendForAnimation()
        }
        let canPresent = scenePhase == .active && !animationsPlaying
            && !gameState.isResolvingTurn && !settingsVisible && !confirmNewGame
        if canPresent && onboarding.activeJourney == nil && !onboarding.pendingJourneys.isEmpty {
            if onboarding.pendingJourneys.first?.blocksGameInteraction == true {
                gameState.pauseTimer()
            }
            onboarding.presentIfPossible(true)
        }
        if scenePhase == .active && !onboardingBlocksInteraction {
            gameState.resumeTimer()
        } else {
            gameState.pauseTimer()
        }
    }

    private func finishDeal() {
        onboarding.dealCompleted()
        guard !reduceMotion else {
            isDealComplete = true
            hasCompletedInitialDeal = true
            return
        }
        footerAnimating = true
        withAnimation(.easeInOut(duration: 0.2), completionCriteria: .removed) {
            isDealComplete = true
            hasCompletedInitialDeal = true
        } completion: {
            footerAnimating = false
        }
    }

    private func startNewGame() {
        guard isDealComplete else { return }
        onboarding.newGame()
        isDealComplete = false
        gameState.setupNewGame()
        dealID = UUID()
    }
}

// Partial: Game footer view
private struct GameFooterView: View {
    let isDealComplete: Bool
    let hasCompletedInitialDeal: Bool
    let onNewGame: () -> Void
    let onSettings: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onNewGame) {
                Label("New Game", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityHidden(!isDealComplete)

            Button(action: onSettings) {
                Label("Settings", systemImage: "gear")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityHidden(!isDealComplete)
        }
        .padding(.horizontal)
        .disabled(!isDealComplete)
        .opacity(isDealComplete ? 1 : (hasCompletedInitialDeal ? 0.2 : 0))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isDealComplete)
        .accessibilityHidden(!isDealComplete)
    }
}

// Partial: Game score view
private struct GameScoreView: View {
    let gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Score: \(gameState.score)")
                .font(.title2)
                .bold()
            Text("Flips: \(gameState.flips)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// Partial: Game timer view
private struct GameTimerView: View {
    let gameState: GameState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "timer")
            Text("\(gameState.timeRemaining)s")
                .font(.title2)
                .bold()
                .foregroundStyle(gameState.timeRemaining <= 10 ? .red : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// Partial: Game result overlay view
private struct GameResultOverlay: View {
    let gameState: GameState
    let onPlayAgain: () -> Void

    var body: some View {
        if gameState.isGameOver {
            GameOverView(
                won: gameState.gameWon,
                score: gameState.score,
                flips: gameState.flips,
                timeElapsed: gameState.timeLimit - gameState.timeRemaining,
                onPlayAgain: onPlayAgain
            )
        }
    }
}
