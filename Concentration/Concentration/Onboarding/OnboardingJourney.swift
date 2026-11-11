// Onboarding journeys for the Concentration game

enum OnboardingJourney: String, CaseIterable, Identifiable {
    case firstPlay
    case puzzleComplete
    case timeOut
    case firstMismatch
    case firstMatch

    var id: String { rawValue }

    var blocksGameInteraction: Bool { true }

    var features: [OBFeature] {
        switch self {
        case .firstPlay:
            [
                OBFeature(
                    title: "Hello! Welcome!",
                    description: "Welcome to the game. Find pairs.",
                    icon: "square.on.square"
                ),
                OBFeature(
                    title: "Find a Pair",
                    description: "Tap two cards to reveal them.",
                    icon: "square.on.square"
                ),
                OBFeature(
                    title: "Watch the Clock",
                    description: "The timer starts when you flip your first card.",
                    icon: "timer"
                ),
                OBFeature(
                    title: "Match Them All",
                    description: "Match every pair before time runs out.",
                    icon: "star"
                )
            ]

        case .puzzleComplete:
            [
                OBFeature(
                    title: "Improve Your Score",
                    description: "Find all the pairs faster to earn a larger time bonus.",
                    icon: "trophy"
                )
            ]

        case .timeOut:
            [
                OBFeature(
                    title: "Time’s Up",
                    description: "Remember the cards you've seen and try again.",
                    icon: "clock"
                )
            ]
        case .firstMismatch:
            [
                OBFeature(
                    title: "Remember the Cards",
                    description: "Remember where these cards were for your next turn.",
                    icon: "xmark"
                )
            ]
        case .firstMatch:
            [
                OBFeature(
                    title: "You got a match!",
                    description: "Matched cards stay face up. Now, find the remaining pairs.",
                    icon: "checkmark"
                )
            ]
        }
    }
}
