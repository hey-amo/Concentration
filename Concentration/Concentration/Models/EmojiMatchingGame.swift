//
//  EmojiMatchingGame.swift
//  Concentration
//
//  Created by Amarjit on 04/11/2025.
//

// From Stanford tutorial

struct EmojiCard {
    var isFaceUp: Bool
    var isMatched: Bool
    var content: CardContent
}

func createCardContent(forPairIndex: Int) -> String {
    let emojis = ["🐶", "🐱", "🐭", "🦊", "🐹", "🐰", "🐻", "🐼", "🐨", "🐯"]
    return emojis[forPairIndex]
    
}

struct MemoryGame<CardContent> {
    private var cards: Array<EmojiCard>
    
    init(numberOfPairs: Int = 5, cardContentFactory: (Int) -> CardContent ) {
        cards = []
        // add numberOfPairs * 2
        for pairIndex in 0..<numberOfPairs {
            let content: CardContent = cardContentFactory(pairIndex)
            cards.append( EmojiCard.init(isFaceUp: false, isMatched: false, content: content as! CardContent) )
            cards.append( EmojiCard.init(isFaceUp: false, isMatched: false, content: content as! CardContent) )
        }
    }
    
    func choose(_ card: EmojiCard) {
        
    }
}

class EmojiMatchingGame {
    
    

    private var model: MemoryGame<String>(numberOfPairs: 4)
    var cards: [Card]
    
    init(model: MemoryGame, cards: [Card]) {
        self.model = model
        self.cards = cards
    }
}
