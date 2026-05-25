import SwiftUI

struct SettingsView: View {
    @State private var page = SettingsPage.general

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar(selection: $page)
                .frame(width: 188)

            Divider()

            VStack(spacing: 0) {
                SettingsPageHeader(page: page)

                Divider()

                pageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
    }

    @ViewBuilder
    private var pageContent: some View {
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
        case .connections:
            ConnectionsSettingsView()
        case .aiAssistant:
            AIAssistantSettingsView()
        case .ghostty:
            GhosttyConfigSettingsView()
        }
    }
}

private enum SettingsPage: String, CaseIterable, Identifiable {
    case general
    case appearance
    case commands
    case editor
    case sessions
    case recording
    case notifications
    case connections
    case aiAssistant
    case ghostty

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
        case .connections: "Connections"
        case .aiAssistant: "AI Assistant"
        case .ghostty: "Ghostty"
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
        case .connections: "Remote, mobile, usage"
        case .aiAssistant: "Commit and PR generation"
        case .ghostty: "Terminal emulator config"
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
        case .connections: "network"
        case .aiAssistant: "sparkles"
        case .ghostty: "terminal"
        }
    }
}

private struct SettingsSidebar: View {
    @Binding var selection: SettingsPage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.top, 14)
                .padding(.bottom, 8)

            ForEach(SettingsPage.allCases) { page in
                SettingsSidebarRow(
                    page: page,
                    isSelected: selection == page,
                    action: { selection = page }
                )
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }
}

private struct SettingsSidebarRow: View {
    let page: SettingsPage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: page.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? MuxyTheme.accent : .secondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(page.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(.primary)
                    Text(page.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected ? AnyShapeStyle(MuxyTheme.accentSoft) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 7)
            )
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

private struct SettingsPageHeader: View {
    let page: SettingsPage

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: page.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MuxyTheme.accent)
                .frame(width: 28, height: 28)
                .background(MuxyTheme.accentSoft, in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 1) {
                Text(page.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(page.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

private struct SettingsWindowConfigurator: NSViewRepresentable {
    let minSize: NSSize

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            window.styleMask.insert(.resizable)
            window.minSize = minSize
            if window.frame.width < minSize.width || window.frame.height < minSize.height {
                var frame = window.frame
                frame.size.width = max(frame.size.width, minSize.width)
                frame.size.height = max(frame.size.height, minSize.height)
                window.setFrame(frame, display: true)
            }
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}
