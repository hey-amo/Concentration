import SwiftUI

struct GameBoardView: View {
    let cards: [Card]
    let isReady: Bool
    let onSelect: (UUID) -> Void
    let onDealComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shuffleOffset: CGFloat = 0
    @State private var isDealing = false
    @State private var animationID = UUID()

    private let columnCount = 5
    private let spacing: CGFloat = 12

    var body: some View {
        let rows = (cards.count + columnCount - 1) / columnCount

        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount),
            spacing: spacing
        ) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                GeometryReader { geometry in
                    CardView(card: card) {
                        onSelect(card.id)
                    }
                    .disabled(!isReady)
                    .accessibilityHidden(!isReady)
                    .accessibilityIdentifier("card-\(index)")
                    .offset(
                        x: isDealing ? 0 : (CGFloat(columnCount - 1) / 2 - CGFloat(index % columnCount)) * (geometry.size.width + spacing),
                        y: isDealing ? 0 : (CGFloat(rows - 1) / 2 - CGFloat(index / columnCount)) * (geometry.size.height + spacing)
                    )
                    .opacity(isDealing ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(duration: 0.45).delay(Double(index) * 0.035),
                        value: isDealing
                    )
                }
                .aspectRatio(0.7, contentMode: .fit)
                .zIndex(Double(cards.count - index))
            }
        }
        .padding()
        .overlay {
            if !isReady && !reduceMotion {
                shuffleDeck
                    .opacity(isDealing ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: isDealing)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .allowsHitTesting(isReady)
        .accessibilityHidden(!isReady)
        .task {
            await dealCards()
        }
        .onDisappear {
            animationID = UUID()
        }
    }

    private var shuffleDeck: some View {
        GeometryReader { geometry in
            let cardWidth = (geometry.size.width - 32 - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
            ZStack {
                deckCard
                    .offset(x: -shuffleOffset)
                    .rotationEffect(.degrees(-Double(shuffleOffset) / 3))
                deckCard
                    .offset(x: shuffleOffset)
                    .rotationEffect(.degrees(Double(shuffleOffset) / 3))
                deckCard
            }
            .frame(width: cardWidth, height: cardWidth / 0.7)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private var deckCard: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.blue.gradient)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.6), lineWidth: 2)
            }
            .shadow(radius: 3)
    }

    @MainActor
    private func dealCards() async {
        guard !isReady else { return }
        let currentAnimationID = UUID()
        animationID = currentAnimationID
        if reduceMotion {
            isDealing = true
            onDealComplete()
            return
        }

        do {
            isDealing = false
            shuffleOffset = 0
            withAnimation(.easeInOut(duration: 0.3)) { shuffleOffset = 28 }
            try await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 0.3)) { shuffleOffset = 0 }
            try await Task.sleep(for: .milliseconds(300))
            withAnimation(.default, completionCriteria: .removed) {
                isDealing = true
            } completion: {
                guard animationID == currentAnimationID else { return }
                onDealComplete()
            }
        } catch is CancellationError {
            // A new game or view removal cancels the previous deal.
        } catch {
            assertionFailure("Unexpected deal delay error: \(error)")
        }
    }
}
