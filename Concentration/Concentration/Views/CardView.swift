//
//  CardView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation
import SwiftUI

struct CardView: View {
    let card: Card
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
            Button(action: onTap) {
                ZStack {
                    // Card Back
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                        .opacity(card.isFaceUp ? 0 : 1)
                    
                    // Card Front
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .overlay(
                            Text(card.emoji)
                                .font(.system(size: 50))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(card.isMatched ? .blue : .clear, lineWidth: 3)
                        )
                        .overlay(alignment: .topTrailing) {
                            if card.isMatched {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                                    .padding(8)
                            }
                        }
                        .opacity(card.isFaceUp ? 1 : 0)
                }
                .rotation3DEffect(
                    .degrees(card.isFaceUp ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(duration: 0.6), value: card.isFaceUp)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .disabled(card.isMatched)
        }
}
