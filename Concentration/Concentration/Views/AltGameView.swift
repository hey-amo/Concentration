//
//  AltGameView.swift
//  Concentration
//
//  Created by Amarjit on 07/11/2025.
//

import SwiftUI
import Foundation

class AltGameModel {
    let emojiis = [ "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯" ]
    var cards: [AltCard]
    var isGameOver: Bool
    var gameWon: Bool
    
    init(cards: [AltCard], isGameOver: Bool = false, gameWon: Bool = false) {
        self.cards = cards
        self.isGameOver = isGameOver
        self.gameWon = gameWon
    }
}

struct AltCard: Identifiable, Codable, Equatable {
    let id: UUID
    let emojii: String
    var isFaceup: Bool
    var isMatched: Bool
    let position: Int
    
    static func == (left: AltCard, right: AltCard) -> Bool {
        return (left.id == right.id)
    }
}

// MARK: AltGameView

struct AltGameView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
