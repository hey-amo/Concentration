//
//  GameState.swift
//  Concentration
//
//  Created by Amarjit on 03/11/2025.
//

import Foundation
import Observation

enum SoundEffect {
    case cardFlip, match, noMatch, win, lose
}

enum HapticType {
    case success, error, light
}

struct GameStats: Codable, Sendable {
    var score: Int
    var flips: Int
    var timeElapsed: Int
    var isComplete: Bool
}

@MainActor
@Observable
final class GameState {
    private(set) var cards: [Card]
    private(set) var flips = 0
    private(set) var score = 0
    private(set) var timeRemaining: Int
    private(set) var isGameOver = false
    private(set) var gameWon = false
    private(set) var timerStarted = false
    private(set) var isResolvingTurn = false

    let timeLimit: Int

    @ObservationIgnored private var selectedCardIDs: [UUID] = []
    @ObservationIgnored private var gameID = UUID()
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private let turnResolutionDelay: Duration

    init(
        cards: [Card]? = nil,
        turnResolutionDelay: Duration = .milliseconds(800),
        timeLimit: Int = 90
    ) {
        self.timeLimit = timeLimit
        self.timeRemaining = timeLimit
        self.cards = Self.faceDown(cards ?? Self.makeDeck())
        self.turnResolutionDelay = turnResolutionDelay
    }

    func setupNewGame() {
        timerTask?.cancel()
        timerTask = nil
        gameID = UUID()
        selectedCardIDs.removeAll()
        isResolvingTurn = false
        score = 0
        flips = 0
        timeRemaining = timeLimit
        isGameOver = false
        gameWon = false
        timerStarted = false
        cards = Self.makeDeck()
    }

    func selectCard(_ cardID: UUID) async {
        guard !isGameOver,
              !isResolvingTurn,
              let index = cards.firstIndex(where: { $0.id == cardID }),
              !cards[index].isFaceUp,
              !cards[index].isMatched else {
            return
        }

        cards[index].isFaceUp = true
        flips += 1
        selectedCardIDs.append(cardID)

        if !timerStarted {
            timerStarted = true
            startTimer()
        }

        playSound(.cardFlip)

        guard selectedCardIDs.count == 2 else { return }

        isResolvingTurn = true
        let resolvingGameID = gameID
        let firstCardID = selectedCardIDs[0]
        let secondCardID = selectedCardIDs[1]

        do {
            try await Task.sleep(for: turnResolutionDelay)
        } catch is CancellationError {
            guard gameID == resolvingGameID else { return }
            turnCardsDown([firstCardID, secondCardID])
            selectedCardIDs.removeAll()
            isResolvingTurn = false
            return
        } catch {
            assertionFailure("Unexpected turn-resolution delay error: \(error)")
            guard gameID == resolvingGameID else { return }
            turnCardsDown([firstCardID, secondCardID])
            selectedCardIDs.removeAll()
            isResolvingTurn = false
            return
        }

        guard gameID == resolvingGameID else { return }
        guard !isGameOver else {
            selectedCardIDs.removeAll()
            isResolvingTurn = false
            return
        }
        guard let firstIndex = cards.firstIndex(where: { $0.id == firstCardID }),
              let secondIndex = cards.firstIndex(where: { $0.id == secondCardID }) else {
            return
        }

        if cards[firstIndex].pairId == cards[secondIndex].pairId {
            cards[firstIndex].isMatched = true
            cards[secondIndex].isMatched = true
            score += 10
            playSound(.match)
            triggerHaptic(.success)

            if cards.allSatisfy(\.isMatched) {
                endGame(won: true)
            }
        } else {
            turnCardsDown([firstCardID, secondCardID])
            playSound(.noMatch)
            triggerHaptic(.error)
        }

        selectedCardIDs.removeAll()
        isResolvingTurn = false
    }

    private static func makeDeck() -> [Card] {
        var deck: [Card] = []
        for character in Character.allCases {
            let pairID = UUID()
            deck.append(Card(character: character, pairId: pairID, position: 0))
            deck.append(Card(character: character, pairId: pairID, position: 0))
        }

        return deck.shuffled().enumerated().map { index, card in
            Card(
                id: card.id,
                character: card.character,
                pairId: card.pairId,
                position: index
            )
        }
    }

    private static func faceDown(_ cards: [Card]) -> [Card] {
        cards.map { card in
            var faceDownCard = card
            faceDownCard.isFaceUp = false
            faceDownCard.isMatched = false
            return faceDownCard
        }
    }

    private func turnCardsDown(_ cardIDs: [UUID]) {
        for cardID in cardIDs {
            guard let index = cards.firstIndex(where: { $0.id == cardID }),
                  !cards[index].isMatched else {
                continue
            }
            cards[index].isFaceUp = false
        }
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch is CancellationError {
                    return
                } catch {
                    assertionFailure("Unexpected timer error: \(error)")
                    return
                }

                guard !Task.isCancelled,
                      let self,
                      self.timeRemaining > 0,
                      !self.isGameOver else {
                    return
                }
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 { self.endGame(won: false) }
            }
        }
    }

    func pauseTimer() {
        timerTask?.cancel()
        timerTask = nil
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
            let timeElapsed = timeLimit - timeRemaining
            let multiplier = calculateTimeBonus(timeElapsed: timeElapsed)
            score = Int(Double(score) * multiplier)
            playSound(.win)
            triggerHaptic(.success)
        } else {
            playSound(.lose)
            triggerHaptic(.error)
        }

        let stats = GameStats(
            score: score,
            flips: flips,
            timeElapsed: timeLimit - timeRemaining,
            isComplete: isGameOver
        )
        Task {
            await PersistenceManager.shared.saveGame(stats)
        }
    }

    private func calculateTimeBonus(timeElapsed: Int) -> Double {
        switch timeElapsed {
        case 0...20: return 3.0
        case 21...30: return 2.5
        case 31...45: return 2.0
        case 46...60: return 1.5
        default: return 1.0
        }
    }

    private func playSound(_ sound: SoundEffect) {
    }

    private func triggerHaptic(_ type: HapticType) {
    }
}
