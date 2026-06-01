import AppKit
import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("muxy.notifications.sound") private var sound = NotificationSound.funk.rawValue
    @AppStorage("muxy.notifications.toastEnabled") private var toastEnabled = true
    @AppStorage("muxy.notifications.toastPosition") private var toastPosition = ToastPosition.topCenter.rawValue

    var body: some View {
        SettingsContainer {
            SettingsSection("Delivery") {
                SettingsToggleRow(label: "Toast", isOn: $toastEnabled)
            }

            SettingsSection("Sound") {
                SettingsPickerRow<NotificationSound>(
                    label: "Sound",
                    selection: $sound
                )
                .onChange(of: sound) { _, newValue in
                    previewSound(newValue)
                }
            }

            SettingsSection("Toast") {
                SettingsPickerRow<ToastPosition>(
                    label: "Position",
                    selection: $toastPosition
                )
            }

            SettingsSection("AI Providers", showsDivider: false) {
                HStack {
                    Text("Install hooks for tools detected on this Mac.")
                        .font(.system(size: SettingsMetrics.footnoteFontSize))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Install All") {
                        AIProviderRegistry.shared.installAll(force: true)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: SettingsMetrics.footnoteFontSize))
                }
                .padding(.horizontal, SettingsMetrics.horizontalPadding)
                .padding(.top, SettingsMetrics.rowVerticalPadding)

                ForEach(AIProviderRegistry.shared.providers, id: \.id) { provider in
                    ProviderToggleRow(provider: provider)
                }
            }
        }
    }

    private func previewSound(_ value: String) {
        guard let sound = NotificationSound(rawValue: value), sound != .none else { return }
        NSSound(named: .init(sound.rawValue))?.play()
    }
}

private struct ProviderToggleRow: View {
    let provider: AIProviderIntegration
    @State private var enabled: Bool
    @State private var refreshed = false

    init(provider: AIProviderIntegration) {
        self.provider = provider
        _enabled = State(initialValue: provider.isEnabled)
    }

    var body: some View {
        HStack {
            Image(systemName: provider.iconName)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(provider.displayName)
                .font(.system(size: SettingsMetrics.labelFontSize))
            Spacer()
            if enabled {
                Button {
                    AIProviderRegistry.shared.forceInstall(provider)
                    withAnimation { refreshed = true }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { refreshed = false }
                    }
                } label: {
                    if refreshed {
                        Label("Done", systemImage: "checkmark")
                    } else {
                        Text("Refresh")
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: SettingsMetrics.footnoteFontSize))
                .foregroundStyle(refreshed ? .green : Color.accentColor)
                .disabled(refreshed)
            }
            Toggle("", isOn: $enabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: enabled) { _, newValue in
                    provider.isEnabled = newValue
                    AIProviderRegistry.shared.installAll(force: true)
                }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }
}
