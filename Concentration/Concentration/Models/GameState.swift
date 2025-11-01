//
//  GameState.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation
import Observation

struct GameStats: Codable {
    var score: Int
    var flips: Int
    var timeElapsed: Int
    var isComplete: Bool
}

enum SoundEffect {
    case cardFlip, match, noMatch, win, lose
}

enum HapticType {
    case success, error, light
}

// MARK: - Game State
// MARK: - Game State

@Observable
class GameState {
    var cards: [Card] = []
    var flips: Int = 0
    var score: Int = 0
    var timeRemaining: Int = 90
    var isGameOver: Bool = false
    var gameWon: Bool = false
    
    private var startTime: Date?
    private var timerTask: Task<Void, Never>?
    
    let coordinator = GameCoordinator()
    
    private let animalEmojis = ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯"]
    
    init() {
        setupNewGame()
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
        startTime = Date()
        
        // Create 10 pairs (20 cards) for 5x4 grid
        var newCards: [Card] = []
        for (index, emoji) in animalEmojis.enumerated() {
            let pairId = UUID()
            newCards.append(Card(emoji: emoji, pairId: pairId, position: index * 2))
            newCards.append(Card(emoji: emoji, pairId: pairId, position: index * 2 + 1))
        }
        
        // Shuffle
        cards = newCards.shuffled()
        
        // Update positions after shuffle
        for (index, _) in cards.enumerated() {
            cards[index] = Card(
                id: cards[index].id,
                emoji: cards[index].emoji,
                pairId: cards[index].pairId,
                position: index
            )
        }
        
        // Reset coordinator
        Task {
            await coordinator.reset()
        }
        
        // Start timer
        startTimer()
    }
    
    @MainActor
    func selectCard(_ card: Card) {
        Task {
            let canSelect = await coordinator.canSelectCard(card.id, currentState: cards)
            guard canSelect else { return }
            
            // Flip card face up
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                cards[index].isFaceUp = true
                flips += 1
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
                   let card2 = cards.first(where: { $0.id == selectedIds[1] }),
                   card1.pairId == card2.pairId {
                    // Match!
                    handleMatch(card1: card1, card2: card2, baseScore: baseScore)
                } else {
                    // No match
                    handleNoMatch(cardIds: selectedIds)
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
        }
        if let index2 = cards.firstIndex(where: { $0.id == card2.id }) {
            cards[index2].isMatched = true
        }
        
        score += baseScore
        playSound(.match)
        triggerHaptic(.success)
        
        // Check if game is won
        if cards.allSatisfy({ $0.isMatched }) {
            endGame(won: true)
        }
    }
    
    private func handleNoMatch(cardIds: [UUID]) {
        Task {
            // Flip cards back down
            for cardId in cardIds {
                if let index = cards.firstIndex(where: { $0.id == cardId }) {
                    cards[index].isFaceUp = false
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
        if !isGameOver && timeRemaining > 0 {
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
