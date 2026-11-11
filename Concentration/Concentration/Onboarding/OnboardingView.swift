import SwiftUI

struct OnboardingView: View {
    let appName: String
    let features: [OBFeature]
    let color: Color
    var onFinish: () -> Void

    @State private var currentStep = 0

    init(
        appName: String,
        features: [OBFeature],
        color: Color = .blue,
        onFinish: @escaping () -> Void = {}
    ) {
        self.appName = appName
        self.features = features
        self.color = color
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("🐻")
                    .font(.largeTitle)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(appName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if features.indices.contains(currentStep) {
                        Text(features[currentStep].title)
                            .font(.headline)
                    } else {
                        Text("No tips available")
                            .font(.headline)
                    }
                }
                Spacer(minLength: 0)
                if features.indices.contains(currentStep), let icon = features[currentStep].icon {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .accessibilityHidden(true)
                }
            }

            if features.indices.contains(currentStep) {
                Text(features[currentStep].description)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if !features.isEmpty {
                    Text("Tip \(currentStep + 1) of \(features.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if currentStep + 1 < features.count {
                    Button("Skip", action: onFinish)
                        .foregroundStyle(.secondary)
                    Button("Next") { currentStep += 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(color)
                } else {
                    Button("Done", action: onFinish)
                        .buttonStyle(.borderedProminent)
                        .tint(color)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 380)
    }
}

#Preview("Game tips") {
    OnboardingView(
        appName: "Concentration",
        features: [
            OBFeature(title: "Find a Pair", description: "Tap two cards to reveal them. Match their pictures to score points.", icon: "square.on.square"),
            OBFeature(title: "Watch the Clock", description: "The timer starts when you flip your first card.", icon: "timer"),
            OBFeature(title: "Keep Going", description: "Match every pair before time runs out.", icon: "star")
        ],
        color: .blue
    )
    .padding()
}
