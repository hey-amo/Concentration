//
//  Card.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation

struct Card: Identifiable, Hashable, Equatable, Codable {
    let id: UUID
    let animal: Animal
    let pairId: UUID
    var isFaceUp: Bool
    var isMatched: Bool
    let position: Int
    
    init(id: UUID = UUID(), animal: Animal, pairId: UUID, isFaceUp: Bool = false, isMatched: Bool = false, position: Int) {
        self.id = id
        self.animal = animal
        self.pairId = pairId
        self.isFaceUp = isFaceUp
        self.isMatched = isMatched
        self.position = position
    }
    
    var emoji: String {
        return animal.emoji
    }
}
