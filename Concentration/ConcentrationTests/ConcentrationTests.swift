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

    func testTimerExpiryDuringTurnResolutionRemainsALoss() async throws {
        let (_, firstPair, _) = makeGame()
        let game = GameState(
            cards: firstPair,
            turnResolutionDelay: .seconds(2),
            timeLimit: 1
        )
        let pair = game.cards

        await game.selectCard(pair[0].id)
        let secondSelection = Task { @MainActor in
            await game.selectCard(pair[1].id)
        }

        let deadline = ContinuousClock.now + .milliseconds(1_800)
        while !game.isGameOver && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }

        XCTAssertTrue(game.isGameOver, "The one-second timer should expire before turn resolution.")
        XCTAssertEqual(game.timeRemaining, 0)
        XCTAssertFalse(game.gameWon)

        await secondSelection.value

        XCTAssertTrue(game.isGameOver)
        XCTAssertFalse(game.gameWon)
        XCTAssertEqual(game.score, 0)
        XCTAssertTrue(game.cards.allSatisfy { !$0.isMatched })
        XCTAssertFalse(game.isResolvingTurn)
    }

    func testSelectingAlreadyFaceUpCardDoesNotCountAnotherFlip() async throws {
        let (game, firstPair, _) = makeGame()

        await game.selectCard(firstPair[0].id)
        await game.selectCard(firstPair[0].id)

        XCTAssertTrue(try card(firstPair[0].id, in: game).isFaceUp)
        XCTAssertEqual(game.flips, 1)
    }

    func testMismatchIsPublishedToGameEventObserver() async {
        let observer = GameEventRecorder()
        let (game, firstPair, secondPair) = makeGame()
        let observedGame = GameState(
            cards: game.cards,
            turnResolutionDelay: .zero,
            eventObserver: observer
        )

        await observedGame.selectCard(firstPair[0].id)
        await observedGame.selectCard(secondPair[0].id)

        XCTAssertEqual(observer.events, [.mismatch])
    }

    func testGameHistoryCanBeLoadedAndReset() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).dat")
        let persistence = PersistenceManager(fileURL: fileURL)
        let result = GameStats(
            score: 100,
            flips: 12,
            timeElapsed: 30,
            isComplete: true,
            isWin: true
        )

        try await persistence.saveGame(result)
        let savedHistory = try await persistence.loadGames()
        XCTAssertEqual(savedHistory, [result])

        try await persistence.resetGameData()
        let resetHistory = try await persistence.loadGames()
        XCTAssertTrue(resetHistory.isEmpty)
    }

    private func card(_ id: UUID, in game: GameState) throws -> Card {
        try XCTUnwrap(game.cards.first { $0.id == id })
    }

    @MainActor
    private final class GameEventRecorder: GameEventObserving {
        private(set) var events: [GameEvent] = []

        func gameEventOccurred(_ event: GameEvent) {
            events.append(event)
        }
    }
}
