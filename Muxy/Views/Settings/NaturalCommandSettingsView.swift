import SwiftUI

struct NaturalCommandSettingsView: View {
    @State private var settings = NaturalCommandSettings.shared

    var body: some View {
        SettingsContainer {
            SettingsSection(
                "Natural Commands",
                footer: [
                    "Natural-language requests are always reviewed before running.",
                    "Destructive requests generate inspect-only commands in this experiment.",
                ].joined(separator: " ")
            ) {
                SettingsToggleRow(label: "Enable", isOn: $settings.isEnabled)
                SettingsPickerRow<NaturalCommandBackendMode>(
                    label: "Backend",
                    selection: $settings.backendMode
                )
            }

            SettingsSection(
                "Ollama",
                footer: "Used when Apple Intelligence is unavailable or when Ollama is selected."
            ) {
                SettingsRow("Base URL") {
                    TextField("", text: $settings.ollamaBaseURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .frame(width: SettingsMetrics.controlWidth)
                }
                SettingsRow("Model") {
                    TextField("", text: $settings.ollamaModel)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .frame(width: SettingsMetrics.controlWidth)
                }
            }
        }
    }
}
