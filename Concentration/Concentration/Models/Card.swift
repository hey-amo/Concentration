//
//  Card.swift
//  Concentration
//
//  Created by Amarjit on 03/11/2025.
//

import Foundation

// Emojis
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

extension Card: CustomStringConvertible {
    var description: String {
        return String.localizedStringWithFormat("id: \(self.id.uuidString), \(self.emoji)")
    }
}
