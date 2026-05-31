import SwiftUI

struct SettingsView: View {
    @State private var page: SettingsPage? = .general

    var body: some View {
        NavigationSplitView {
            List(SettingsPage.allCases, selection: $page) { item in
                SettingsSidebarLabel(page: item)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: WindowLayoutMetrics.settingsSidebarMinWidth,
                ideal: WindowLayoutMetrics.settingsSidebarIdealWidth,
                max: WindowLayoutMetrics.settingsSidebarMaxWidth
            )
        } detail: {
            if let page {
                settingsDetail(for: page)
            } else {
                ContentUnavailableView(
                    "Select a Settings Page",
                    systemImage: "gearshape",
                    description: Text("Choose a category in the sidebar.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(
            minWidth: WindowLayoutMetrics.settingsMinWidth,
            minHeight: WindowLayoutMetrics.settingsMinHeight
        )
        .background(SettingsWindowConfigurator(minSize: NSSize(
            width: WindowLayoutMetrics.settingsMinWidth,
            height: WindowLayoutMetrics.settingsMinHeight
        )))
        .background(Color(nsColor: .windowBackgroundColor))
        .resetsSettingsFocusOnOutsideClick()
        .onAppear(perform: consumeMCPToolsFocusRequest)
        .onReceive(NotificationCenter.default.publisher(for: .focusMCPToolsSettings)) { _ in
            page = .mcpTools
            consumeMCPToolsFocusRequest()
        }
    }

    private func consumeMCPToolsFocusRequest() {
        guard SettingsFocusCoordinator.shared.consume(.mcpTools) else { return }
        page = .mcpTools
    }

    private func settingsDetail(for page: SettingsPage) -> some View {
        VStack(spacing: 0) {
            SettingsPageHeader(page: page)

            Divider()

            pageContent(for: page)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .settingsContentWidthAware()
    }

    @ViewBuilder
    private func pageContent(for page: SettingsPage) -> some View {
        switch page {
        case .general:
            GeneralSettingsView()
        case .appearance:
            AppearanceSettingsView()
        case .commands:
            CommandsSettingsView()
        case .editor:
            EditorSettingsView()
        case .sessions:
            SessionRestoreSettingsView()
        case .recording:
            RecordingSettingsView()
        case .notifications:
            NotificationSettingsView()
        case .network:
            NetworkSettingsView()
        case .connections:
            ConnectionsSettingsView()
        case .aiAssistant:
            AIAssistantSettingsView()
        case .ghostty:
            GhosttyConfigSettingsView()
        case .mcpTools:
            MCPToolsSettingsView()
        }
    }
}

private enum SettingsPage: String, CaseIterable, Identifiable, Hashable {
    case general
    case appearance
    case commands
    case editor
    case sessions
    case recording
    case notifications
    case network
    case connections
    case aiAssistant
    case ghostty
    case mcpTools

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .appearance: "Appearance"
        case .commands: "Commands"
        case .editor: "Editor"
        case .sessions: "Sessions"
        case .recording: "Recording"
        case .notifications: "Notifications"
        case .network: "Network"
        case .connections: "Connections"
        case .aiAssistant: "AI Assistant"
        case .ghostty: "Ghostty"
        case .mcpTools: "MCP Tools"
        }
    }

    var subtitle: String {
        switch self {
        case .general: "Features, projects, tabs"
        case .appearance: "Themes and layout"
        case .commands: "Shortcuts and actions"
        case .editor: "Files and markdown"
        case .sessions: "Terminal session restore"
        case .recording: "Voice and screen capture"
        case .notifications: "Alerts and providers"
        case .network: "Remote access on your LAN"
        case .connections: "SSH spaces, pairing, usage"
        case .aiAssistant: "Commit and PR generation"
        case .ghostty: "Terminal emulator config"
        case .mcpTools: "Obsidian and MCP servers"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .appearance: "paintbrush"
        case .commands: "sparkles"
        case .editor: "pencil.line"
        case .sessions: "clock.arrow.circlepath"
        case .recording: "mic"
        case .notifications: "bell"
        case .network: "globe"
        case .connections: "link"
        case .aiAssistant: "sparkles"
        case .ghostty: "terminal"
        case .mcpTools: "puzzlepiece.extension"
        }
    }
}

private struct SettingsSidebarLabel: View {
    let page: SettingsPage

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .font(.system(size: 12, weight: .medium))
                Text(page.subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } icon: {
            Image(systemName: page.icon)
                .font(.system(size: 12, weight: .medium))
        }
    }
}

private struct SettingsPageHeader: View {
    @Environment(\.settingsContentWidth) private var contentWidth
    let page: SettingsPage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: page.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MuxyTheme.accent)
                .frame(width: 28, height: 28)
                .background(MuxyTheme.accentSoft, in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 2) {
                Text(page.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(page.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(SettingsLayout.isCompact(contentWidth: contentWidth) ? 3 : 2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, 13)
    }
}

private final class SettingsWindowAnchorView: NSView {
    var minSize = NSSize(width: WindowLayoutMetrics.settingsMinWidth, height: WindowLayoutMetrics.settingsMinHeight)

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowPolicy()
    }

    func applyWindowPolicy() {
        guard let window else { return }
        var styleMask = window.styleMask
        styleMask.insert(.resizable)
        styleMask.insert(.miniaturizable)
        window.styleMask = styleMask
        window.minSize = minSize
    }
}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    let minSize: NSSize

    func makeNSView(context _: Context) -> SettingsWindowAnchorView {
        let view = SettingsWindowAnchorView()
        view.minSize = minSize
        return view
    }

    func updateNSView(_ nsView: SettingsWindowAnchorView, context _: Context) {
        nsView.minSize = minSize
        nsView.applyWindowPolicy()
    }
}
