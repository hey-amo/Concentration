import SwiftUI

struct GameView: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @State private var gameState = GameState(eventObserver: HapticsController())
    @State private var showSettings = false
    @State private var confirmNewGame = false
    @State private var dealID = UUID()
    @State private var isDealComplete = false
    @State private var hasCompletedInitialDeal = false

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    Spacer()
                    GameTimerView(gameState: gameState)
                }
                .padding(.horizontal)

                GameBoardView(
                    cards: gameState.cards,
                    isReady: isDealComplete,
                    onSelect: { cardID in
                        guard isDealComplete else { return }
                        Task { await gameState.selectCard(cardID) }
                    },
                    onDealComplete: {
                        isDealComplete = true
                        hasCompletedInitialDeal = true
                    }
                )
                .id(dealID)

                HStack(spacing: 20) {
                    Button {
                        confirmNewGame = true
                    } label: {
                        Label("New Game", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityHidden(!isDealComplete)

                    Button {
                        showSettings = true
                    } label: {
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
            .padding(.vertical)

            GameResultOverlay(gameState: gameState, onPlayAgain: startNewGame)
        }
        .preferredColorScheme(AppAppearance(rawValue: appearanceMode)?.colorScheme)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Start a New Game?", isPresented: $confirmNewGame) {
            Button("Start New Game", role: .destructive, action: startNewGame)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current game progress will be lost.")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                gameState.pauseTimer()
            case .active:
                gameState.resumeTimer()
            @unknown default:
                gameState.pauseTimer()
            }
        }
    }

    private func startNewGame() {
        guard isDealComplete else { return }
        isDealComplete = false
        gameState.setupNewGame()
        dealID = UUID()
    }
}

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
