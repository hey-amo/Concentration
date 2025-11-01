//
//  HeaderView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import SwiftUI
import Foundation

struct HeaderView: View {
    @State var gameState: GameState
    
    var body: some View {        
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
        
    }
    
}

