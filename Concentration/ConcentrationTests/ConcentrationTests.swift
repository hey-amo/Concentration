import Foundation
import XCTest
@testable import Concentration

@MainActor
final class ConcentrationTests: XCTestCase {
    private func makeGame(
        turnResolutionDelay: Duration = .zero
    ) -> (game: GameState, firstPair: [Card], secondPair: [Card]) {
        let firstPairID = UUID()
        let secondPairID = UUID()
        let cards = [
            Card(character: .dog, pairId: firstPairID, position: 0),
            Card(character: .dog, pairId: firstPairID, position: 1),
            Card(character: .cat, pairId: secondPairID, position: 2),
            Card(character: .cat, pairId: secondPairID, position: 3)
        ]
        return (
            GameState(cards: cards, turnResolutionDelay: turnResolutionDelay),
            Array(cards[0...1]),
            Array(cards[2...3])
        )
    }

    func testNewGameStartsWithEveryCardFaceDown() {
        let game = GameState()

        XCTAssertEqual(game.cards.count, Character.allCases.count * 2)
        XCTAssertTrue(game.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
        XCTAssertEqual(game.flips, 0)
    }

    func testSelectingOneCardTurnsOnlyThatCardFaceUp() async throws {
        let (game, firstPair, _) = makeGame()

        await game.selectCard(firstPair[0].id)

        XCTAssertTrue(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertFalse(try card(firstPair[1].id, in: game).isFaceUp)
        XCTAssertEqual(game.flips, 1)
    }

    func testNonmatchingPairTurnsBothCardsFaceDownAfterSecondSelection() async throws {
        let (game, firstPair, secondPair) = makeGame()

        await game.selectCard(firstPair[0].id)
        XCTAssertTrue(try card(firstPair[0].id, in: game).isFaceUp)

        await game.selectCard(secondPair[0].id)

        XCTAssertFalse(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertFalse(try card(secondPair[0].id, in: game).isFaceUp)
        XCTAssertFalse(try card(firstPair[0].id, in: game).isMatched)
        XCTAssertFalse(try card(secondPair[0].id, in: game).isMatched)
        XCTAssertEqual(game.flips, 2)
        XCTAssertFalse(game.isResolvingTurn)

        await game.selectCard(firstPair[0].id)
        XCTAssertTrue(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertEqual(game.flips, 3)
    }

    func testMatchingPairStaysFaceUpAndAwardsPoints() async throws {
        let (game, firstPair, _) = makeGame()

        await game.selectCard(firstPair[0].id)
        await game.selectCard(firstPair[1].id)

        for matchingCard in firstPair {
            XCTAssertTrue(try card(matchingCard.id, in: game).isFaceUp)
            XCTAssertTrue(try card(matchingCard.id, in: game).isMatched)
        }
        XCTAssertEqual(game.score, 10)
        XCTAssertEqual(game.flips, 2)
    }

    func testCannotSelectAnotherCardWhilePairIsBeingResolved() async throws {
        let (game, firstPair, secondPair) = makeGame(
            turnResolutionDelay: .milliseconds(100)
        )

        await game.selectCard(firstPair[0].id)
        let secondSelection = Task { @MainActor in
            await game.selectCard(secondPair[0].id)
        }

        while !game.isResolvingTurn {
            await Task.yield()
        }
        await game.selectCard(firstPair[1].id)
        await secondSelection.value

        XCTAssertFalse(try card(firstPair[1].id, in: game).isFaceUp)
        XCTAssertFalse(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertFalse(try card(secondPair[0].id, in: game).isFaceUp)
        XCTAssertEqual(game.flips, 2)
    }

    func testStartingNewGameDuringResolutionIgnoresTheOldTurn() async throws {
        let (game, firstPair, secondPair) = makeGame(
            turnResolutionDelay: .milliseconds(100)
        )

        await game.selectCard(firstPair[0].id)
        let secondSelection = Task { @MainActor in
            await game.selectCard(secondPair[0].id)
        }
        while !game.isResolvingTurn {
            await Task.yield()
        }

        game.setupNewGame()
        await secondSelection.value

        XCTAssertEqual(game.cards.count, Character.allCases.count * 2)
        XCTAssertTrue(game.cards.allSatisfy { !$0.isFaceUp && !$0.isMatched })
        XCTAssertEqual(game.flips, 0)
        XCTAssertEqual(game.score, 0)
        XCTAssertFalse(game.isResolvingTurn)
    }

    func testSelectingAlreadyFaceUpCardDoesNotCountAnotherFlip() async throws {
        let (game, firstPair, _) = makeGame()

        await game.selectCard(firstPair[0].id)
        await game.selectCard(firstPair[0].id)

        XCTAssertTrue(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertEqual(game.flips, 1)
    }

    private func card(_ id: UUID, in game: GameState) throws -> Card {
        try XCTUnwrap(game.cards.first { $0.id == id })
    }
}
