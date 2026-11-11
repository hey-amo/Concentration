import Foundation

// Onboarding feature struct

struct OBFeature: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String?

    init(id: UUID = UUID(), title: String, description: String, icon: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
    }
}

// Extension specific onboarding journeys
// :first-play-journey (first-time journey)
/*
 OBFeature(title: "Find a Pair", description: "Tap two cards to reveal them. Match their pictures to score points.", icon: "square.on.square"),
 OBFeature(title: "Watch the Clock", description: "The timer starts when you flip your first card.", icon: "timer"),
 OBFeature(title: "Keep Going", description: "Match every pair before time runs out.", icon: "star")
 */
// :puzzle-complete-journey (congratulate the user on completing the puzzle)
// :time-out-journey (the player ran out of time)
// what else?
