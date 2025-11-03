//
//  SettingsView.swift
//  Concentration
//
//  Created by Amarjit on 01/11/2025.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    Toggle("Sound effects", isOn: .constant(true))
                    Toggle("Background music", isOn: .constant(true))
                }
                Section("Display") {
                    Toggle("Dark mode", isOn: .constant(true))
                }
                Section("Game") {
                    Button("Reset game data") {
                        // Do something
                    }
                }
                
                /*
                Section("Game Info") {
                    LabeledContent("Grid Size", value: "5×4 (20 cards)")
                    LabeledContent("Time Limit", value: "90 seconds")
                }
                
                Section("Time Bonuses") {
                    LabeledContent("0-20s", value: "3× multiplier")
                    LabeledContent("21-30s", value: "2.5× multiplier")
                    LabeledContent("31-45s", value: "2× multiplier")
                    LabeledContent("46-60s", value: "1.5× multiplier")
                    LabeledContent("60s+", value: "No bonus")
                }
                */
                
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
