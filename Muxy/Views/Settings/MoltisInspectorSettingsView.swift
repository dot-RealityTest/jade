import SwiftUI

struct MoltisInspectorSettingsView: View {
    @State private var settings = MoltisAssistantSettings.shared
    @State private var gateway = MoltisProcessManager.shared

    var body: some View {
        SettingsSection(
            "Inspector Chat (Experimental)",
            footer: footerText
        ) {
            SettingsPickerRow<MoltisAssistantBackend>(
                label: "Routing",
                selection: $settings.backendSelection
            )
            if settings.backend == .both {
                SettingsToggleRow(
                    label: "Fallback to Ollama direct",
                    isOn: $settings.fallbackToOllama
                )
            }
            SettingsRow("Gateway port") {
                TextField("", value: $settings.preferredGatewayPort, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .settingsControlFrame()
            }
            SettingsRow("Status") {
                Text(statusLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .settingsControlFrame(alignment: .trailing)
            }
            HStack {
                Spacer()
                Button("Restart gateway") {
                    Task {
                        _ = try? await gateway.restart()
                    }
                }
                .disabled(!MoltisBundledBinary.isAvailable)
            }
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.bottom, 4)
        }
    }

    private var statusLabel: String {
        switch gateway.status {
        case .stopped:
            MoltisBundledBinary.isAvailable ? "Stopped" : "Binary missing"
        case .starting:
            "Starting…"
        case let .running(port, version):
            if let version {
                "Running on \(port) (\(version))"
            } else {
                "Running on \(port)"
            }
        case let .failed(message):
            "Failed: \(message)"
        }
    }

    private var footerText: String {
        let ollama = NaturalCommandSettings.shared
        let routing = settings.backend == .both
            ? "Both: Moltis (via Ollama) is tried first, then direct Ollama if the gateway fails."
            : "Ollama direct only — Moltis is not used."
        return [
            routing,
            "Ollama: \(ollama.ollamaBaseURL), model \(ollama.ollamaModel) (Commands → Natural Commands).",
            "Restart gateway after Ollama URL or model changes.",
            "Debug builds only — release builds use Ollama direct for inspector chat.",
        ].joined(separator: " ")
    }
}
