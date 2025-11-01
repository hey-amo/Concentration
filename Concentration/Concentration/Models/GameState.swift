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
    
    deinit {
        // Cancel timer immediately
        timerTask?.cancel()
        
        // Note: Actor cleanup
        // The GameCoordinator actor will be deallocated automatically
        // when GameState is deallocated since there are no external
        // references to it. Swift's actor model handles this.
    }
    
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
        print ("Creating cards...")
        var newCards: [Card] = []
        for (index, emoji) in animalEmojis.enumerated() {
            let pairId = UUID()
            newCards.append(Card(emoji: emoji, pairId: pairId, position: index * 2))
            newCards.append(Card(emoji: emoji, pairId: pairId, position: index * 2 + 1))
        }
        
        // Shuffle
        cards = newCards.shuffled()
        print ("Shuffled \(cards.count) cards")
            
        // Update positions after shuffle
        for (index, _) in cards.enumerated() {
            cards[index] = Card(
                id: cards[index].id,
                emoji: cards[index].emoji,
                pairId: cards[index].pairId,
                position: index
            )
        }
        
        // Reset the coordinator
        Task {
            await coordinator.reset()
        }
        
        // Start the timer
        startTimer()
    }
    
    private func endGame(won: Bool = false) {
        isGameOver = true
        gameWon = won
        timerTask?.cancel()
        
        if won {
            print ("Won... Calculating bonus")
           // Calculate time bonus
           let timeElapsed = 90 - timeRemaining
           let multiplier = calculateTimeBonus(timeElapsed: timeElapsed)
           score = Int(Double(score) * multiplier)
           //playSound(.win)
           //triggerHaptic(.success)
       } else {
           print ("Lost")
           //playSound(.lose)
           //triggerHaptic(.error)
       }
        
        // Save game
        //Task {
        //    await PersistenceManager.shared.saveGame(self)
        //}
    }

    
    // MARK: Time Bonus
    
    private func calculateTimeBonus(timeElapsed: Int) -> Double {
        switch timeElapsed {
        case 0...20: return 3.0  // 3x bonus
        case 21...30: return 2.5 // 2.5x bonus
        case 31...45: return 2.0 // 2x bonus
        case 46...60: return 1.5 // 1.5x bonus
        default: return 1.0      // No bonus
        }
    }

    // MARK: Timer
    
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
    
    // MARK: Audio & Haptics
    
    private func playSound(_ sound: SoundEffect) {
       //Task.detached(priority: .background) {
           // Implement audio playback here
           // await AudioManager.shared.play(sound)
       //}
    }
    
    private func triggerHaptic(_ type: HapticType) {
    }
}
