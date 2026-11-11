import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode = AppAppearance.system.rawValue
    @Bindable private var audioManager = AudioManager.shared
    @State private var gameHistory: [GameStats] = []
    @State private var showingResetConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    Toggle("Sound effects", isOn: $audioManager.isSoundEffectsEnabled)
                    Toggle("Background music", isOn: $audioManager.isBackgroundMusicEnabled)
                }

                Section("Display") {
                    Picker("Appearance", selection: $appearanceMode) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title).tag(appearance.rawValue)
                        }
                    }
                }

                Section("Game data") {
                    LabeledContent("Games played", value: "\(gameHistory.count)")
                    LabeledContent("Wins", value: "\(gameHistory.filter(\.isWin).count)")
                    LabeledContent("Best score", value: "\(gameHistory.map(\.score).max() ?? 0)")
                    Button("Reset game data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                    .disabled(gameHistory.isEmpty)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete all saved game results?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset game data", role: .destructive) {
                    Task { await resetGameData() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your sound and appearance preferences will be kept.")
            }
            .alert("Unable to update game data", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadGameHistory()
            }
        }
    }

    private func loadGameHistory() async {
        do {
            gameHistory = try await PersistenceManager.shared.loadGames()
        } catch {
            present(error)
        }
    }

    private func resetGameData() async {
        do {
            try await PersistenceManager.shared.resetGameData()
            gameHistory = []
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}
