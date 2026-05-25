import AppKit
import SwiftUI

struct MCPToolsSettingsView: View {
    @Bindable private var store = ObsidianMCPSettingsStore.shared
    @State private var isTestingConnection = false
    @State private var isRefreshingTools = false
    @State private var testStatusMessage: String?
    @State private var discoveredTools: [MCPToolDescriptor] = ObsidianMCPToolCatalog.builtIn
    @State private var toolsStatusMessage: String?

    var body: some View {
        SettingsContainer {
            SettingsSection(
                "Obsidian MCP",
                footer: """
                Uses obsidian-codex-mcp over stdio. Install the server, then point Jade at your vault, Python, and server.py. \
                Send to Obsidian captures selection, rich input, or clipboard text into your inbox folder.
                """,
                showsDivider: true
            ) {
                SettingsToggleRow(label: "Enable Obsidian MCP", isOn: binding(\.isEnabled))

                SettingsRow("Repository") {
                    if let repositoryURL = URL(string: ObsidianMCPSettings.repositoryURL) {
                        Link("obsidian-codex-mcp", destination: repositoryURL)
                            .font(.system(size: SettingsMetrics.footnoteFontSize))
                    }
                }

                configurablePathRow(
                    label: "Vault Path",
                    path: binding(\.vaultPath),
                    chooseTitle: "Select Obsidian Vault",
                    canChooseFiles: false
                )

                if let vaultWarning = ObsidianVaultPathValidator.validationMessage(for: store.vaultPath) {
                    validationRow(vaultWarning)
                }

                configurablePathRow(
                    label: "Python",
                    path: binding(\.pythonPath),
                    chooseTitle: "Select Python Executable",
                    canChooseFiles: true
                )

                configurablePathRow(
                    label: "server.py",
                    path: binding(\.serverScriptPath),
                    chooseTitle: "Select obsidian-codex-mcp server.py",
                    canChooseFiles: true
                )

                SettingsRow("Inbox Folder") {
                    TextField("Jade/Inbox", text: binding(\.inboxFolder))
                        .textFieldStyle(.roundedBorder)
                        .settingsControlFrame()
                }

                SettingsRow("Default Tags") {
                    TextField("jade", text: binding(\.defaultTags))
                        .textFieldStyle(.roundedBorder)
                        .settingsControlFrame()
                }

                SettingsToggleRow(label: "Read Only", isOn: binding(\.readOnly))
                SettingsToggleRow(label: "Backup on Write", isOn: binding(\.backupOnWrite))

                SettingsRow("Connection") {
                    HStack(spacing: 8) {
                        Button(isTestingConnection ? "Testing…" : "Test MCP") {
                            testConnection()
                        }
                        .disabled(isTestingConnection || !store.snapshot.isServerConfigured)

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

            SettingsSection("Available Tools", footer: toolsFooter, showsDivider: false) {
                SettingsRow("Tool Catalog") {
                    Button(isRefreshingTools ? "Refreshing…" : "Refresh Tools") {
                        refreshTools()
                    }
                    .disabled(isRefreshingTools || !store.snapshot.isServerConfigured)
                }

                if let toolsStatusMessage {
                    validationRow(toolsStatusMessage)
                }

                ForEach(discoveredTools) { tool in
                    toolRow(tool)
                }
            }
        }
        .onAppear {
            if store.snapshot.isServerConfigured {
                refreshTools()
            }
        }
    }

    private var toolsFooter: String {
        "These tools come from the connected MCP server. Use the command palette to run common Obsidian actions."
    }

    private func binding<Value>(_ keyPath: ReferenceWritableKeyPath<ObsidianMCPSettingsStore, Value>) -> Binding<Value> {
        Binding(
            get: { store[keyPath: keyPath] },
            set: { store[keyPath: keyPath] = $0 }
        )
    }

    private func configurablePathRow(
        label: String,
        path: Binding<String>,
        chooseTitle: String,
        canChooseFiles: Bool
    ) -> some View {
        VStack(spacing: 0) {
            SettingsRow(label) {
                Button("Choose…") {
                    choosePath(
                        title: chooseTitle,
                        initialPath: path.wrappedValue,
                        canChooseFiles: canChooseFiles
                    ) { url in
                        guard let url else { return }
                        path.wrappedValue = SettingsPathPicker.normalizedPath(from: url)
                    }
                }
            }

            SettingsRow("") {
                TextField(canChooseFiles ? "Path" : "Folder path", text: path)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                    .settingsControlFrame()
            }
        }
    }

    private func toolRow(_ tool: MCPToolDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tool.name)
                .font(.system(size: SettingsMetrics.labelFontSize, weight: .semibold, design: .monospaced))
            Text(tool.description)
                .font(.system(size: SettingsMetrics.footnoteFontSize))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func validationRow(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func choosePath(
        title: String,
        initialPath: String,
        canChooseFiles: Bool,
        onChoose: @escaping (URL?) -> Void
    ) {
        if canChooseFiles {
            SettingsPathPicker.chooseFile(title: title, initialPath: initialPath, completion: onChoose)
        } else {
            SettingsPathPicker.chooseDirectory(title: title, initialPath: initialPath, completion: onChoose)
        }
    }

    func testConnection() {
        isTestingConnection = true
        testStatusMessage = nil
        Task {
            let result = await ObsidianSendService.testConnection(settings: store.snapshot)
            await MainActor.run {
                isTestingConnection = false
                switch result {
                case let .success(count):
                    testStatusMessage = "Connected. \(count) notes in inbox folder."
                case let .failure(error):
                    testStatusMessage = error.localizedDescription
                }
            }
        }
    }

    func refreshTools() {
        isRefreshingTools = true
        toolsStatusMessage = nil
        Task {
            let result = await ObsidianMCPService.discoverTools(settings: store.snapshot)
            await MainActor.run {
                isRefreshingTools = false
                switch result {
                case let .success(tools):
                    discoveredTools = tools
                    toolsStatusMessage = "Loaded \(tools.count) tools from the MCP server."
                case let .failure(error):
                    discoveredTools = ObsidianMCPToolCatalog.builtIn
                    toolsStatusMessage = error.localizedDescription
                }
            }
        }
    }
}
