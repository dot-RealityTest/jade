import SwiftUI

struct WorkspaceChromeTrailingActions: View {
    let layoutPickerProjectID: UUID?
    let openInIDEProjectPath: String?
    let openInIDEFilePath: String?
    let openInIDECursorProvider: () -> (line: Int?, column: Int?)
    let panelState: WorkspaceChromePanelState
    let showsSplitActions: Bool
    let showVCSButton: Bool
    let showDevelopmentBadge: Bool
    let showMaximizeButton: Bool
    let isMaximized: Bool
    let onSplit: (SplitDirection) -> Void
    let onCreateTab: () -> Void
    let onCreateVCSTab: () -> Void
    let onQuickOpen: () -> Void
    let onToggleFileTree: () -> Void
    let onToggleSnippets: () -> Void
    let onToggleNotes: () -> Void
    let onToggleTodo: () -> Void
    let onToggleAIAssistant: () -> Void
    let onToggleMaximize: (() -> Void)?

    @AppStorage(ToolbarAction.storageKey) private var toolbarActionsRaw = ToolbarAction.defaultRawValue

    var body: some View {
        HStack(spacing: 0) {
            if showsToolbarAction(.debug), showDevelopmentBadge {
                DebugButton()
                    .padding(.trailing, UIMetrics.spacing3)
            }
            if showsToolbarAction(.updates), let version = UpdateService.shared.availableUpdateVersion {
                UpdateBadge(version: version) {
                    UpdateService.shared.checkForUpdates()
                }
                .padding(.trailing, UIMetrics.spacing2)
            }
            if showsToolbarAction(.tools), layoutPickerProjectID != nil {
                OpenInIDEControl(
                    projectPath: openInIDEProjectPath,
                    filePath: openInIDEFilePath,
                    cursorProvider: openInIDECursorProvider
                )
                if let layoutPickerProjectID {
                    LayoutPickerMenu(projectID: layoutPickerProjectID)
                }
            }
            if showMaximizeButton || isMaximized, let onToggleMaximize {
                let symbol = isMaximized
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right"
                let label = isMaximized ? "Restore Pane" : "Maximize Pane"
                IconButton(symbol: symbol, accessibilityLabel: label, action: onToggleMaximize)
                    .help(shortcutTooltip("Toggle Maximize Pane", for: .toggleMaximizePane))
            }
            if showsSplitActions {
                if showsToolbarAction(.splitRight) {
                    IconButton(symbol: "square.split.2x1", accessibilityLabel: "Split Right") {
                        onSplit(.horizontal)
                    }
                    .help(shortcutTooltip("Split Right", for: .splitRight))
                }
                if showsToolbarAction(.splitDown) {
                    IconButton(symbol: "square.split.1x2", accessibilityLabel: "Split Down") {
                        onSplit(.vertical)
                    }
                    .help(shortcutTooltip("Split Down", for: .splitDown))
                }
                if showsToolbarAction(.quickOpen) {
                    IconButton(symbol: "doc.text", size: 12, accessibilityLabel: "Quick Open", action: onQuickOpen)
                        .help(shortcutTooltip("Quick Open", for: .quickOpen))
                }
                if showsToolbarAction(.sourceControl), showVCSButton {
                    FileDiffIconButton(action: onCreateVCSTab)
                        .help(shortcutTooltip("Source Control", for: .openVCSTab))
                }
                if showsToolbarAction(.fileTree), showVCSButton {
                    FileTreeIconButton(action: onToggleFileTree)
                        .help(shortcutTooltip("File Tree", for: .toggleFileTree))
                }
            }
            if showsToolbarAction(.snippets), layoutPickerProjectID != nil {
                IconButton(
                    symbol: "curlybraces",
                    size: 12,
                    color: WorkspaceChromePanelAccent.color(
                        requested: panelState.snippetsVisible,
                        suppressed: panelState.snippetsSuppressed
                    ),
                    accessibilityLabel: "Snippets",
                    action: onToggleSnippets
                )
                .help(shortcutTooltip("Snippets", for: .toggleSnippetsPanel))
            }
            if showsToolbarAction(.notes), layoutPickerProjectID != nil {
                IconButton(
                    symbol: "note.text",
                    size: 12,
                    color: WorkspaceChromePanelAccent.color(
                        requested: panelState.notesVisible,
                        suppressed: panelState.inspectorSuppressed
                    ),
                    accessibilityLabel: "Notes",
                    action: onToggleNotes
                )
                .help(shortcutTooltip("Notes", for: .toggleProjectNotesPanel))
            }
            if showsToolbarAction(.todo), layoutPickerProjectID != nil {
                IconButton(
                    symbol: "checklist",
                    size: 12,
                    color: WorkspaceChromePanelAccent.color(
                        requested: panelState.todoVisible,
                        suppressed: panelState.inspectorSuppressed
                    ),
                    accessibilityLabel: "Todo",
                    action: onToggleTodo
                )
                .help(shortcutTooltip("Todo", for: .toggleProjectTodoPanel))
            }
            if showsToolbarAction(.newTab), layoutPickerProjectID != nil {
                IconButton(symbol: "plus", accessibilityLabel: "New Tab", action: onCreateTab)
                    .help(shortcutTooltip("New Tab", for: .newTab))
            }
            IconButton(
                symbol: "bubble.left.and.bubble.right",
                size: 12,
                color: WorkspaceChromePanelAccent.color(
                    requested: panelState.aiVisible,
                    suppressed: panelState.aiSuppressed
                ),
                accessibilityLabel: "AI Assistant",
                action: onToggleAIAssistant
            )
            .help(shortcutTooltip("AI Assistant", for: .toggleAIAssistant))
        }
        .padding(.leading, UIMetrics.spacing4)
        .padding(.trailing, UIMetrics.spacing2)
        .fixedSize(horizontal: true, vertical: false)
    }

    private func showsToolbarAction(_ action: ToolbarAction) -> Bool {
        ToolbarAction.visibleActions(from: toolbarActionsRaw).contains(action)
    }

    private func shortcutTooltip(_ name: String, for action: ShortcutAction) -> String {
        "\(name) (\(KeyBindingStore.shared.combo(for: action).displayString))"
    }
}
