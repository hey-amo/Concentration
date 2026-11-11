import SwiftUI

struct OnboardingView: View {
    let appName: String
    let features: [OBFeature]
    let color: Color
    var onFinish: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var currentStep = 0
    @AccessibilityFocusState private var titleFocused: Bool

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
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($titleFocused)
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

            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading) {
                    progress
                    actions
                }
            } else {
                HStack {
                    progress
                    Spacer()
                    actions
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 380)
        .accessibilityIdentifier("onboarding")
        .task {
            titleFocused = true
        }
    }

    @ViewBuilder
    private var progress: some View {
        if !features.isEmpty {
            Text("Tip \(currentStep + 1) of \(features.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actions: some View {
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

#Preview("First play") {
    OnboardingView(
        appName: "Concentration",
        features: OnboardingJourney.firstPlay.features
    )
    .padding()
}

#Preview("Puzzle complete") {
    OnboardingView(
        appName: "Concentration",
        features: OnboardingJourney.puzzleComplete.features
    )
    .padding()
}

#Preview("Time out") {
    OnboardingView(
        appName: "Concentration",
        features: OnboardingJourney.timeOut.features
    )
    .padding()
}