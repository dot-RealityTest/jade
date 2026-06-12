import AppKit
import SwiftUI

struct LogCaptureSettingsView: View {
    @Bindable private var store = ObsidianCaptureSettingsStore.shared
    @State private var isTestingFolder = false
    @State private var testStatusMessage: String?

    var body: some View {
        SettingsContainer {
            SettingsSection(
                "Markdown Logs",
                footer: """
                Session logs and captures are written as markdown files into this folder. \
                Point it at an Obsidian vault to get linked notes, or any folder for plain markdown.
                """,
                showsDivider: true
            ) {
                folderRow

                if let warning = ObsidianVaultPathValidator.validationMessage(for: store.vaultPath) {
                    validationRow(warning)
                }

                SettingsRow("Folder Check") {
                    HStack(spacing: 8) {
                        Button(isTestingFolder ? "Testing…" : "Test Folder") {
                            testFolder()
                        }
                        .disabled(isTestingFolder || !store.snapshot.isVaultConfigured)

                        if let testStatusMessage {
                            Text(testStatusMessage)
                                .font(.system(size: SettingsMetrics.footnoteFontSize))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .frame(maxWidth: 220, alignment: .leading)
                        }
                    }
                }
            }

            SettingsSection(
                "Capture",
                footer: "Send to Obsidian appends quick captures to the default note, or creates a new note per capture.",
                showsDivider: false
            ) {
                SettingsRow("Default Capture Note") {
                    TextField("Jade/Inbox/capture.md", text: binding(\.defaultCaptureNotePath))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                        .settingsControlFrame()
                }

                SettingsRow("Capture Write Mode") {
                    Picker("", selection: binding(\.captureWriteMode)) {
                        ForEach(ObsidianCaptureWriteMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .settingsControlFrame(alignment: .trailing)
                }

                SettingsRow("Inbox Folder") {
                    TextField("Jade/Inbox", text: binding(\.inboxFolder))
                        .textFieldStyle(.roundedBorder)
                        .settingsControlFrame()
                }
            }
        }
    }

    private var folderRow: some View {
        VStack(spacing: 0) {
            SettingsRow("Logs Folder") {
                Button("Choose…") {
                    SettingsPathPicker.chooseDirectory(
                        title: "Select Logs Folder",
                        initialPath: store.vaultPath
                    ) { url in
                        guard let url else { return }
                        store.vaultPath = SettingsPathPicker.normalizedPath(from: url)
                    }
                }
            }

            SettingsRow("") {
                TextField("Folder path (e.g. your Obsidian vault)", text: binding(\.vaultPath))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                    .settingsControlFrame()
            }
        }
    }

    private func binding<Value>(
        _ keyPath: ReferenceWritableKeyPath<ObsidianCaptureSettingsStore, Value>
    ) -> Binding<Value> {
        Binding(
            get: { store[keyPath: keyPath] },
            set: { store[keyPath: keyPath] = $0 }
        )
    }

    private func validationRow(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    func testFolder() {
        isTestingFolder = true
        testStatusMessage = nil
        let result = ObsidianSendService.testConnection(settings: store.snapshot)
        isTestingFolder = false
        switch result {
        case let .success(count):
            testStatusMessage = "Folder ready. \(count) notes in inbox folder."
        case let .failure(error):
            testStatusMessage = error.localizedDescription
        }
    }
}
