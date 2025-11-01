//
//  BottomView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import SwiftUI

struct BottomView: View {
    @State var gameState: GameState
    @State var showSettings = false
    
    var body: some View {
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
}
