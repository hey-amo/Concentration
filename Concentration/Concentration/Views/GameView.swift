//
//  GameView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation
import SwiftUI

@MainActor
struct GameView: View {
    @State private var gameState = GameState()
    @State private var showSettings = false
    @State private var showGameOver = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Score: \(gameState.score)")
                            .font(.title2)
                            .bold()
                        Text("Flips: \(gameState.flips)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Timer
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                        Text("\(gameState.timeRemaining)s")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(gameState.timeRemaining <= 10 ? .red : .primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                
                // Game Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(gameState.cards) { card in
                        CardView(card: card) {
                            gameState.selectCard(card)
                        }
                        .aspectRatio(0.7, contentMode: .fit)
                    }
                }
                .padding()
                
                // Bottom Buttons
                HStack(spacing: 20) {
                    Button {
                        gameState.setupNewGame()
                    } label: {
                        Label("New Game", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            // Game Over Overlay
            if gameState.isGameOver {
                GameOverView(
                    won: gameState.gameWon,
                    score: gameState.score,
                    flips: gameState.flips,
                    timeElapsed: 90 - gameState.timeRemaining,
                    onPlayAgain: {
                        gameState.setupNewGame()
                    }
                )
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                gameState.pauseTimer()
            case .active:
                gameState.resumeTimer()
            @unknown default:
                gameState.pauseTimer()
            }
        }
    }
}
