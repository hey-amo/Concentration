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
// :first-play-journey
// :well-done-journey
// what else?
