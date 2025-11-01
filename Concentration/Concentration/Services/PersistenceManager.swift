//
//  PersistenceManager.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation

// MARK: - Persistence Manager

actor PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("concentration_game.dat")
    }()
    
    func saveGame(_ gameState: GameState) async {
        do {
            let stats = GameStats(
                score: gameState.score,
                flips: gameState.flips,
                timeElapsed: 90 - gameState.timeRemaining,
                isComplete: gameState.isGameOver
            )
            
            let data = try JSONEncoder().encode(stats)
            let compressed = try (data as NSData).compressed(using: .lzfse)
            try compressed.write(to: fileURL)
        } catch {
            print("Failed to save game: \(error)")
        }
    }
    
    func loadLastGame() async -> GameStats? {
        do {
            let compressed = try Data(contentsOf: fileURL)
            let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
            return try JSONDecoder().decode(GameStats.self, from: data)
        } catch {
            return nil
        }
    }
}
