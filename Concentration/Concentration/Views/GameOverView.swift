//
//  GameOverView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import SwiftUI

struct GameOverView: View {
    let won: Bool
    let score: Int
    let flips: Int
    let timeElapsed: Int
    let onPlayAgain: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: won ? "trophy.fill" : "clock.badge.xmark")
                    .font(.system(size: 80))
                    .foregroundStyle(won ? .yellow : .red)
                
                Text(won ? "You Won!" : "Time's Up!")
                    .font(.largeTitle)
                    .bold()
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Final Score:")
                        Spacer()
                        Text("\(score)")
                            .bold()
                    }
                    
                    HStack {
                        Text("Total Flips:")
                        Spacer()
                        Text("\(flips)")
                            .bold()
                    }
                    
                    if won {
                        HStack {
                            Text("Time:")
                            Spacer()
                            Text("\(timeElapsed)s")
                                .bold()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button {
                    onPlayAgain()
                } label: {
                    Text("Play Again")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(40)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(40)
        }
    }
}

