import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage(GeneralSettingsKeys.autoExpandWorktreesOnProjectSwitch)
    private var autoExpandWorktrees = false
    @AppStorage(GeneralSettingsKeys.defaultWorktreeParentPath)
    private var defaultWorktreeParentPath = ""
    @AppStorage(GeneralSettingsKeys.fileTreeSource)
    private var fileTreeSourceRaw = FileTreeSourcePreference.defaultValue.rawValue
    @AppStorage(TabCloseConfirmationPreferences.confirmRunningProcessKey)
    private var confirmRunningProcess = true
    @AppStorage(ProjectLifecyclePreferences.keepOpenWhenNoTabsKey)
    private var keepProjectsOpenWhenNoTabs = false
    @AppStorage(GeneralSettingsKeys.restoreSessionOnLaunch)
    private var restoreSessionOnLaunch = true
    @AppStorage(UpdateChannel.storageKey)
    private var updateChannelRaw = UpdateChannel.stable.rawValue
    @AppStorage(ToolbarAction.storageKey)
    private var toolbarActionsRaw = ToolbarAction.defaultRawValue
    @AppStorage(ProjectPickerPreferences.storageKey)
    private var projectPickerModeRaw = ProjectPickerMode.custom.rawValue
    @AppStorage(QuitConfirmationPreferences.confirmQuitKey)
    private var confirmQuit = true
    @AppStorage(GeneralSettingsKeys.autoCopyTerminalSelection)
    private var autoCopyTerminalSelection = false
    @State private var projectPickerDefaultLocationSettings = ProjectPickerDefaultLocationSettingsModel()
    @State private var sentry = SentryService.shared

    var body: some View {
        SettingsContainer {
            SettingsSection(
                "Updates",
                footer: "The Beta channel ships every change merged to main and may be unstable. "
                    + "Switch back to Stable to receive only tagged releases."
            ) {
                SettingsRow("Update channel") {
                    Picker("", selection: channelBinding) {
                        ForEach(UpdateChannel.allCases) { channel in
                            Text(channel.displayName).tag(channel)
                        }
                    }
                    .labelsHidden()
                    .settingsControlFrame(alignment: .trailing)
                }
            }

            SettingsSection(
                "Sidebar",
                footer: "Automatically reveal worktrees when you switch to a project."
            ) {
                SettingsToggleRow(
                    label: "Auto-expand worktrees on project switch",
                    isOn: $autoExpandWorktrees
                )
            }

            SettingsSection(
                "Visible Features",
                footer: "Choose what appears in the title bar. Hidden actions remain available in Cmd+K."
            ) {
                ForEach(ToolbarAction.allCases) { action in
                    toolbarToggleRow(for: action)
                }
                toolbarResetRow
            }

            SettingsSection(
                "File Tree",
                footer: "When set to the active terminal, the file tree follows the working directory of "
                    + "the active terminal tab. If there is no active terminal, it keeps the last known path."
            ) {
                SettingsRow("Root directory") {
                    Picker("", selection: $fileTreeSourceRaw) {
                        ForEach(FileTreeSourcePreference.allCases) { source in
                            Text(source.title).tag(source.rawValue)
                        }
                    }
                    .labelsHidden()
                    .settingsControlFrame(alignment: .trailing)
                }
            }

            SettingsSection(
                "Projects",
                footer: projectsFooter
            ) {
                SettingsRow(AppIdentity.pickerLabel) {
                    Picker("", selection: $projectPickerModeRaw) {
                        ForEach(ProjectPickerMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .labelsHidden()
                    .settingsControlFrame(alignment: .trailing)
                }

                if projectPickerMode == .custom {
                    ProjectPickerDefaultLocationSettingsView(
                        model: projectPickerDefaultLocationSettings,
                        pickerModeRaw: projectPickerModeRaw
                    )
                }

                SettingsToggleRow(
                    label: "Keep projects open after closing the last tab",
                    isOn: $keepProjectsOpenWhenNoTabs
                )
            }

            SettingsSection("Session") {
                SettingsToggleRow(
                    label: "Restore previous session on launch",
                    isOn: $restoreSessionOnLaunch
                )
            }

            SettingsSection(
                "Worktrees",
                footer: "\(AppIdentity.displayName) creates a project-named subfolder inside this folder. "
                    + "Projects can still override this from the new worktree dialog."
            ) {
                worktreeLocationControl
            }

            SettingsSection(
                "Terminal",
                footer: "When enabled, releasing the mouse after selecting text in the terminal copies it to the clipboard."
            ) {
                SettingsToggleRow(
                    label: "Auto-copy selected text",
                    isOn: $autoCopyTerminalSelection
                )
            }

            SettingsSection("Tabs") {
                SettingsToggleRow(
                    label: "Confirm before closing a tab with a running process",
                    isOn: $confirmRunningProcess
                )
            }

            SettingsSection("Quit", showsDivider: sentry.hasDSN) {
                SettingsToggleRow(
                    label: "Confirm before quitting \(AppIdentity.displayName)",
                    isOn: $confirmQuit
                )
            }

            if sentry.hasDSN {
                SettingsSection(
                    "Diagnostics",
                    footer: "Anonymous crash reports help us fix bugs. "
                        + "Reports never include project paths, file contents, or personal data.",
                    showsDivider: false
                ) {
                    SettingsToggleRow(
                        label: "Send anonymous crash reports",
                        isOn: sentryConsentBinding
                    )
                }
            }
        }
    }

    private var sentryConsentBinding: Binding<Bool> {
        Binding(
            get: { sentry.consent == .allowed },
            set: { newValue in sentry.setConsent(newValue ? .allowed : .denied) }
        )
    }

    private var channelBinding: Binding<UpdateChannel> {
        Binding(
            get: { UpdateChannel(rawValue: updateChannelRaw) ?? .stable },
            set: { newValue in
                updateChannelRaw = newValue.rawValue
                UpdateService.shared.channel = newValue
            }
        )
    }

    private func toolbarToggleRow(for action: ToolbarAction) -> some View {
        SettingsRow(action.displayName) {
            HStack(spacing: 8) {
                Text(action.settingsDescription)
                    .font(.system(size: SettingsMetrics.footnoteFontSize))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 220, alignment: .trailing)
                Toggle("", isOn: toolbarActionBinding(for: action))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
    }

    private var toolbarResetRow: some View {
        HStack {
            Spacer()
            Button("Restore Defaults") {
                toolbarActionsRaw = ToolbarAction.defaultRawValue
            }
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .disabled(toolbarActionsRaw == ToolbarAction.defaultRawValue)
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.top, 4)
    }

    private func toolbarActionBinding(for action: ToolbarAction) -> Binding<Bool> {
        Binding(
            get: { ToolbarAction.visibleActions(from: toolbarActionsRaw).contains(action) },
            set: { isVisible in
                var actions = ToolbarAction.visibleActions(from: toolbarActionsRaw)
                if isVisible {
                    actions.insert(action)
                } else {
                    actions.remove(action)
                }
                toolbarActionsRaw = ToolbarAction.rawValue(for: actions)
            }
        )
    }

    private var projectPickerMode: ProjectPickerMode {
        ProjectPickerMode(rawValue: projectPickerModeRaw) ?? .custom
    }

    private var projectsFooter: String {
        if projectPickerMode == .custom {
            return "\(AppIdentity.pickerLabel) starts in this default location. Use App Default to reset it. "
                + "Projects can stay in the sidebar after closing their last tab."
        }
        return "\(AppIdentity.pickerLabel) can use Finder or \(AppIdentity.displayName)'s picker. "
            + "Projects can stay in the sidebar after closing their last tab."
    }

    private var defaultWorktreeLocationText: String {
        defaultWorktreeParentPath.isEmpty ? AppIdentity.appSupportLabel : defaultWorktreeParentPath
    }

    private var worktreeLocationControl: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Default path for new worktrees")
                .font(.system(size: SettingsMetrics.labelFontSize))

            HStack(alignment: .center, spacing: 8) {
                pathDisplay
                    .layoutPriority(1)

                Button("Choose Folder...") {
                    chooseDefaultWorktreeParentPath()
                }
                .fixedSize(horizontal: true, vertical: false)

                Button("Use App Default") {
                    defaultWorktreeParentPath = ""
                }
                .fixedSize(horizontal: true, vertical: false)
                .disabled(defaultWorktreeParentPath.isEmpty)
            }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private var pathDisplay: some View {
        HStack(spacing: 7) {
            Image(systemName: defaultWorktreeParentPath.isEmpty ? "internaldrive" : "folder")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 15)

            Text(defaultWorktreeLocationText)
                .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                .foregroundStyle(defaultWorktreeParentPath.isEmpty ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 9)
        .frame(minWidth: 170, maxWidth: .infinity, alignment: .leading)
        .frame(height: 22)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.quaternary.opacity(0.7), lineWidth: 1)
        )
    }

    private func chooseDefaultWorktreeParentPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select the default folder for new worktrees"
        if let path = WorktreeLocationResolver.normalizedPath(defaultWorktreeParentPath) {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        defaultWorktreeParentPath = url.path
    }
}
