// MARK: - Models

import Foundation
import SwiftUI
import Observation

enum Character: String, CaseIterable, Codable {
    case dog = "🐶"
    case cat = "🐱"
    case mouse = "🐭"
    case hamster = "🐹"
    case rabbit = "🐰"
    case fox = "🦊"
    case bear = "🐻"
    case panda = "🐼"
    case koala = "🐨"
    case tiger = "🐯"
    
    var emoji: String {
        return self.rawValue
    }
}

struct Card: Identifiable, Codable, Equatable {
    let id: UUID
    let character: Character
    let pairId: UUID
    var isFaceUp: Bool
    var isMatched: Bool
    let position: Int
    
    init(id: UUID = UUID(), character: Character, pairId: UUID, position: Int) {
        self.id = id
        self.character = character
        self.pairId = pairId
        self.isFaceUp = false
        self.isMatched = false
        self.position = position
    }
    
    var emoji: String {
        return character.emoji
    }
}

struct GameStats: Codable {
    var score: Int
    var flips: Int
    var timeElapsed: Int
    var isComplete: Bool
}

// MARK: - Game Coordinator Actor

actor GameCoordinator {
    private var isProcessingTurn = false
    private var selectedCardIds: [UUID] = []
    
    enum TurnResult {
        case selected
        case matched(score: Int)
        case noMatch
        case busy
        case alreadySelected
    }
    
    func canSelectCard(_ cardId: UUID, currentState: [Card]) -> Bool {
        // Can't select if processing
        guard !isProcessingTurn else { return false }
        
        // Can't select if already face up or matched
        guard let card = currentState.first(where: { $0.id == cardId }),
              !card.isFaceUp && !card.isMatched else {
            return false
        }
        
        // Can't select if already in selected list
        if selectedCardIds.contains(cardId) {
            return false
        }
        
        // Can't select more than 2 cards
        return selectedCardIds.count < 2
    }
    
    func selectCard(_ cardId: UUID) async -> TurnResult {
        guard !isProcessingTurn else { return .busy }
        
        if selectedCardIds.contains(cardId) {
            return .alreadySelected
        }
        
        selectedCardIds.append(cardId)
        
        if selectedCardIds.count == 2 {
            return await processTurn()
        }
        
        return .selected
    }
    
    private func processTurn() async -> TurnResult {
        isProcessingTurn = true
        
        // Wait for flip animation to complete
        try? await Task.sleep(for: .milliseconds(600))
        
        let card1Id = selectedCardIds[0]
        let card2Id = selectedCardIds[1]
        
        // Wait a moment for player to see both cards
        try? await Task.sleep(for: .milliseconds(800))
        
        let result: TurnResult
        
        // Cards will be checked in GameState
        // Return match result (score calculated in GameState)
        result = .matched(score: 10)
        
        // Reset for next turn
        selectedCardIds.removeAll()
        isProcessingTurn = false
        
        return result
    }
    
    func reset() {
        isProcessingTurn = false
        selectedCardIds.removeAll()
    }
    
    func getSelectedCardIds() -> [UUID] {
        selectedCardIds
    }
}

// MARK: - Game State

@Observable
class GameState {
    var cards: [Card] = []
    var flips: Int = 0
    var score: Int = 0
    var timeRemaining: Int = 90
    var isGameOver: Bool = false
    var gameWon: Bool = false
    var timerStarted: Bool = false
    
    private var startTime: Date?
    private var timerTask: Task<Void, Never>?
    private let instanceID: String
    
    let coordinator = GameCoordinator()
    
    init() {
        self.instanceID = UUID().uuidString.prefix(8).description
        print("🆕 GameState CREATED with ID: \(instanceID)")
        
        // ✅ CRITICAL: Defer setup to avoid triggering observers during init
        Task { @MainActor in
            self.setupNewGame()
        }
    }
    
    deinit {
        print("💀 GameState \(instanceID) DEALLOCATED - THIS SHOULD ONLY HAPPEN WHEN CLOSING APP!")
        timerTask?.cancel()
        print("🛑 All tasks cancelled for \(instanceID)")
    }
    
    func setupNewGame() {
        // Stop existing timer
        timerTask?.cancel()
        
        // Reset state
        score = 0
        flips = 0
        timeRemaining = 90
        isGameOver = false
        gameWon = false
        timerStarted = false
        startTime = Date()
        
        // Create 10 pairs (20 cards) for 5x4 grid using all Character cases
        var newCards: [Card] = []
        for (index, character) in Character.allCases.enumerated() {
            let pairId = UUID()
            newCards.append(Card(character: character, pairId: pairId, position: index * 2))
            newCards.append(Card(character: character, pairId: pairId, position: index * 2 + 1))
        }
        
        // Shuffle
        cards = newCards.shuffled()
        
        // Update positions after shuffle
        for (index, _) in cards.enumerated() {
            cards[index] = Card(
                id: cards[index].id,
                character: cards[index].character,
                pairId: cards[index].pairId,
                position: index
            )
        }
        
        // Reset coordinator
        Task {
            await coordinator.reset()
        }
        
        // Show all cards face up for 3 seconds
        Task { @MainActor in
            print("🎮 New game started - showing all cards for 3 seconds")
            
            // Flip all cards face up (batch update - single mutation)
            cards = cards.map { card in
                var updated = card
                updated.isFaceUp = true
                return updated
            }
            
            // Wait 3 seconds
            try? await Task.sleep(for: .seconds(3))
            
            // Flip all cards face down (batch update - single mutation)
            cards = cards.map { card in
                var updated = card
                updated.isFaceUp = false
                return updated
            }
            
            print("✅ Cards hidden - ready to play!")
        }
        
        // Timer will start on first card flip (see selectCard)
    }
    
    @MainActor
    func selectCard(_ card: Card) {
        Task {
            let canSelect = await coordinator.canSelectCard(card.id, currentState: cards)
            guard canSelect else { return }
            
            // Start timer on first card flip
            if !timerStarted {
                timerStarted = true
                startTimer()
                print("⏱️ Timer started!")
            }
            
            // Flip card face up
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                cards[index].isFaceUp = true
                flips += 1
                print("🃏 Flipped card: \(card.emoji) (Total flips: \(flips))")
            }
            
            // Process selection
            let result = await coordinator.selectCard(card.id)
            
            switch result {
            case .selected:
                // First card selected, wait for second
                playSound(.cardFlip)
                
            case .matched(let baseScore):
                // Check if cards match
                let selectedIds = await coordinator.getSelectedCardIds()
                if selectedIds.count == 2,
                   let card1 = cards.first(where: { $0.id == selectedIds[0] }),
                   let card2 = cards.first(where: { $0.id == selectedIds[1] }) {
                    
                    print("🔍 Checking pair: \(card1.character.emoji) vs \(card2.character.emoji)")
                    
                    if card1.pairId == card2.pairId {
                        // Match!
                        print("✅ Pair found! Well done!")
                        handleMatch(card1: card1, card2: card2, baseScore: baseScore)
                    } else {
                        // No match - flip cards back down
                        print("❌ Not a pair")
                        handleNoMatch(cardIds: selectedIds)
                    }
                }
                
            case .noMatch:
                break
                
            case .busy, .alreadySelected:
                break
            }
        }
    }
    
    private func handleMatch(card1: Card, card2: Card, baseScore: Int) {
        // Mark as matched
        if let index1 = cards.firstIndex(where: { $0.id == card1.id }) {
            cards[index1].isMatched = true
            cards[index1].isFaceUp = true  // Keep face up
        }
        if let index2 = cards.firstIndex(where: { $0.id == card2.id }) {
            cards[index2].isMatched = true
            cards[index2].isFaceUp = true  // Keep face up
        }
        
        score += baseScore
        print("💰 Score increased by \(baseScore), total score: \(score)")
        playSound(.match)
        triggerHaptic(.success)
        
        // Check if game is won
        if cards.allSatisfy({ $0.isMatched }) {
            endGame(won: true)
        }
    }
    
    private func handleNoMatch(cardIds: [UUID]) {
        Task { @MainActor in
            // Wait a moment for player to see both cards
            try? await Task.sleep(for: .milliseconds(800))
            
            // Flip cards back down
            for cardId in cardIds {
                if let index = cards.firstIndex(where: { $0.id == cardId }) {
                    cards[index].isFaceUp = false
                    print("🔄 Flipping card back down: \(cards[index].character.emoji)")
                }
            }
            playSound(.noMatch)
            triggerHaptic(.error)
        }
    }
    
    private func startTimer() {
        timerTask = Task { @MainActor in
            while !Task.isCancelled && timeRemaining > 0 && !isGameOver {
                try? await Task.sleep(for: .seconds(1))
                
                guard !Task.isCancelled else { return }
                
                timeRemaining -= 1
                
                if timeRemaining <= 0 {
                    endGame(won: false)
                }
            }
        }
    }
    
    func pauseTimer() {
        timerTask?.cancel()
    }
    
    func resumeTimer() {
        if !isGameOver && timeRemaining > 0 && timerStarted {
            startTimer()
        }
    }
    
    private func endGame(won: Bool) {
        isGameOver = true
        gameWon = won
        timerTask?.cancel()
        
        if won {
            // Calculate time bonus
            let timeElapsed = 90 - timeRemaining
            let multiplier = calculateTimeBonus(timeElapsed: timeElapsed)
            score = Int(Double(score) * multiplier)
            playSound(.win)
            triggerHaptic(.success)
        } else {
            playSound(.lose)
            triggerHaptic(.error)
        }
        
        // Save game
        Task {
            await PersistenceManager.shared.saveGame(self)
        }
    }
    
    private func calculateTimeBonus(timeElapsed: Int) -> Double {
        switch timeElapsed {
        case 0...20: return 3.0  // 3x bonus
        case 21...30: return 2.5 // 2.5x bonus
        case 31...45: return 2.0 // 2x bonus
        case 46...60: return 1.5 // 1.5x bonus
        default: return 1.0      // No bonus
        }
    }
    
    // MARK: - Audio & Haptics (Placeholder implementations)
    
    private func playSound(_ sound: SoundEffect) {
//        Task.detached(priority: .background) {
//            // Implement audio playback here
//            // await AudioManager.shared.play(sound)
//        }
    }
    
    private func triggerHaptic(_ type: HapticType) {
//        #if os(iOS)
//        Task { @MainActor in
//            switch type {
//            case .success:
//                let generator = UINotificationFeedbackGenerator()
//                generator.notificationOccurred(.success)
//            case .error:
//                let generator = UINotificationFeedbackGenerator()
//                generator.notificationOccurred(.error)
//            case .light:
//                let generator = UIImpactFeedbackGenerator(style: .light)
//                generator.impactOccurred()
//            }
//        }
//        #endif
    }
}

enum SoundEffect {
    case cardFlip, match, noMatch, win, lose
}

enum HapticType {
    case success, error, light
}

// MARK: - Persistence Manager

actor PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("concentration_game.dat")
    }()
    
    func saveGame(_ gameState: GameState) async {
        do {
            let stats = GameStats(
                score: gameState.score,
                flips: gameState.flips,
                timeElapsed: 90 - gameState.timeRemaining,
                isComplete: gameState.isGameOver
            )
            
            let data = try JSONEncoder().encode(stats)
            let compressed = try (data as NSData).compressed(using: .lzfse)
            try compressed.write(to: fileURL)
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    func loadLastGame() async -> GameStats? {
        do {
            let compressed = try Data(contentsOf: fileURL)
            let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
            return try JSONDecoder().decode(GameStats.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Views

struct CardView: View {
    let card: Card
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Card Back
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
                    .opacity(card.isFaceUp ? 0 : 1)
                
                // Card Front
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .overlay(
                        Text(card.emoji)
                            .font(.system(size: 50))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(card.isMatched ? .blue : .clear, lineWidth: 3)
                    )
                    .overlay(alignment: .topTrailing) {
                        if card.isMatched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                                .padding(8)
                        }
                    }
                    .opacity(card.isFaceUp ? 1 : 0)
            }
            .rotation3DEffect(
                .degrees(card.isFaceUp ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.6), value: card.isFaceUp)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(card.isMatched || card.isFaceUp)  // Disable matched and face-up cards
        .opacity(card.isMatched ? 0.9 : 1.0)  // Slightly fade matched cards
    }
}

struct GameView: View {
    @State private var gameState: GameState
    @State private var showSettings = false
    @State private var showGameOver = false
    @State private var viewID = UUID()

    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Initialize GameState once - prevents recreation loop
        _gameState = State(initialValue: GameState())
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Score: \(gameState.score)")
                            .font(.title2)
                            .bold()
                        Text("Flips: \(gameState.flips)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Timer
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
                .padding(.horizontal)
                
                // Game Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(gameState.cards) { card in
                        CardView(card: card) {
                            gameState.selectCard(card)
                        }
                        .aspectRatio(0.7, contentMode: .fit)
                    }
                }
                .padding()
                
                // Bottom Buttons
                HStack(spacing: 20) {
                    Button {
                        gameState.setupNewGame()
                    } label: {
                        Label("New Game", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
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
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            // Game Over Overlay
            if gameState.isGameOver {
                GameOverView(
                    won: gameState.gameWon,
                    score: gameState.score,
                    flips: gameState.flips,
                    timeElapsed: 90 - gameState.timeRemaining,
                    onPlayAgain: {
                        gameState.setupNewGame()
                    }
                )
            }
        }
        .id(viewID)  // ✅ Stable identity for the vie
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
}
