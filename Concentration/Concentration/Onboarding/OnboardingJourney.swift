// Onboarding journeys for the Concentration game

enum OnboardingJourney {
    case firstPlay
    case puzzleComplete
    case timeOut
    case firstMismatch
    case firstMatch

    var features: [OBFeature] {
        switch self {
        case .firstPlay:
            [
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
                    title: "Well Done!",
                    description: "You matched every pair.",
                    icon: "trophy"
                )
            ]

        case .timeOut:
            [
                OBFeature(
                    title: "Time’s Up",
                    description: "Remember the cards you’ve seen and try again.",
                    icon: "clock"
                )
            ]
        case .firstMismatch:
            [
                OBFeature(
                    title: "Oops!",
                    description: "That wasn't a match. Try to remember the cards.",
                    icon: "xmark"
                )
            ]
        case .firstMatch:
            [
                OBFeature(
                    title: "Great!",
                    description: "You found a matching pair! Keep it up.",
                    icon: "checkmark"
                )
            ]
        }
    }
}