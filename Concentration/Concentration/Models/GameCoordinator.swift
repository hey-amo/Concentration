//
//  GameCoordinator.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation

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
              !card.isFaceUp && !card.isMatched else { return false }
        
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
    
    /// Process the turn with `async`
    private func processTurn() async -> TurnResult {
        isProcessingTurn = true
        
        // Wait for flip animation to complete
        try? await Task.sleep(for: .milliseconds(600))
        
        let card1Id = selectedCardIds[0]
        let card2Id = selectedCardIds[1]
        
        print("card1Id = \(card1Id), card2Id = \(card2Id)")
        
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
        return selectedCardIds
    }
}
