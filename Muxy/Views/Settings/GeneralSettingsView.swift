import SwiftUI

enum GeneralSettingsKeys {
    static let autoExpandWorktreesOnProjectSwitch = "muxy.general.autoExpandWorktreesOnProjectSwitch"
}

struct GeneralSettingsView: View {
    @AppStorage(GeneralSettingsKeys.autoExpandWorktreesOnProjectSwitch)
    private var autoExpandWorktrees = false
    @AppStorage(TabCloseConfirmationPreferences.confirmRunningProcessKey)
    private var confirmRunningProcess = true
    @AppStorage(ProjectLifecyclePreferences.keepOpenWhenNoTabsKey)
    private var keepProjectsOpenWhenNoTabs = false
    @AppStorage(UpdateChannel.storageKey)
    private var updateChannelRaw = UpdateChannel.stable.rawValue
    @AppStorage(ToolbarAction.storageKey)
    private var toolbarActionsRaw = ToolbarAction.defaultRawValue

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
                    .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
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
                "Projects",
                footer: "Keep projects in the sidebar after closing their last tab. "
                    + "To remove a project afterward, use the right-click menu."
            ) {
                SettingsToggleRow(
                    label: "Keep projects open after closing the last tab",
                    isOn: $keepProjectsOpenWhenNoTabs
                )
            }

            SettingsSection("Tabs", showsDivider: false) {
                SettingsToggleRow(
                    label: "Confirm before closing a tab with a running process",
                    isOn: $confirmRunningProcess
                )
            }
        }
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
}
