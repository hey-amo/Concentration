//
//  PersistenceManager.swift
//  Concentration
//
//  Created by Amarjit on 03/11/2025.
//

import Foundation

// MARK: - Persistence Manager

actor PersistenceManager {
    static let shared = PersistenceManager()

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("concentration_game.dat")
    }

    func saveGame(_ stats: GameStats) throws {
        var history = try loadGames()
        history.append(stats)
        let data = try JSONEncoder().encode(history)
        let compressed = try (data as NSData).compressed(using: .lzfse)
        try compressed.write(to: fileURL, options: .atomic)
    }

    func loadGames() throws -> [GameStats] {
        do {
            let compressed = try Data(contentsOf: fileURL)
            let data = try (compressed as NSData).decompressed(using: .lzfse) as Data
            let decoder = JSONDecoder()
            do {
                return try decoder.decode([GameStats].self, from: data)
            } catch let historyError {
                do {
                    return [try decoder.decode(GameStats.self, from: data)]
                } catch {
                    throw historyError
                }
            }
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }
    }

    func resetGameData() throws {
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        }
    }
}
