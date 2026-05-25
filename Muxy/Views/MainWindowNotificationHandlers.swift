import SwiftUI

struct MainWindowNotificationHandlers: ViewModifier {
    @Binding var showQuickOpen: Bool
    @Binding var showFindInFiles: Bool
    @Binding var showWorktreeSwitcher: Bool
    @Binding var showProjectPicker: Bool
    @Binding var sidebarExpanded: Bool
    @Binding var isFullScreen: Bool
    @Binding var showCommandPalette: Bool
    @Binding var showThemePicker: Bool
    @Binding var showNotificationPanel: Bool
    @Binding var aiAssistantPanelVisible: Bool

    let openWindow: OpenWindowAction
    let onToggleSnippetsPanel: () -> Void
    let onToggleNotesPanel: () -> Void
    let onToggleTodoPanel: () -> Void
    let onToggleAIAssistantPanel: () -> Void
    let onToggleAttachedVCS: () -> Void
    let onToggleFileTree: () -> Void
    let onToggleRichInput: () -> Void
    let onToggleVoiceRecording: () -> Void
    let onExplainSelection: (Notification) -> Void
    let onApplyAIAssistantCode: (Notification) -> Void

    func body(content: Content) -> some View {
        applyPanelHandlers(to: applyWorkspaceHandlers(to: applyNavigationHandlers(to: content)))
    }

    private func applyNavigationHandlers(to content: some View) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .quickOpen)) { _ in showQuickOpen.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .findInFiles)) { _ in showFindInFiles.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .openProjectPicker)) { _ in showProjectPicker = true }
            .onReceive(NotificationCenter.default.publisher(for: .switchWorktree)) { _ in showWorktreeSwitcher.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSidebar)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) { sidebarExpanded.toggle() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .windowFullScreenDidChange)) { notification in
                isFullScreen = notification.userInfo?["isFullScreen"] as? Bool ?? false
            }
            .onReceive(NotificationCenter.default.publisher(for: .openHelpWindow)) { _ in openWindow(id: "help") }
    }

    private func applyWorkspaceHandlers(to content: some View) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .commandPalette)) { _ in showCommandPalette.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .openVCSWindow)) { _ in openWindow(id: "vcs") }
            .onReceive(NotificationCenter.default.publisher(for: .toggleSnippetsPanel)) { _ in onToggleSnippetsPanel() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleInspectorPanel)) { _ in onToggleNotesPanel() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleProjectNotesPanel)) { _ in onToggleNotesPanel() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleProjectTodoPanel)) { _ in onToggleTodoPanel() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleAIAssistant)) { _ in onToggleAIAssistantPanel() }
    }

    private func applyPanelHandlers(to content: some View) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .explainSelectionWithAI), perform: onExplainSelection)
            .onReceive(NotificationCenter.default.publisher(for: .toggleThemePicker)) { _ in showThemePicker.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleNotificationPanel)) { _ in showNotificationPanel.toggle() }
            .onReceive(NotificationCenter.default.publisher(for: .applyAIAssistantCode), perform: onApplyAIAssistantCode)
            .onReceive(NotificationCenter.default.publisher(for: .toggleAttachedVCS)) { _ in onToggleAttachedVCS() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleFileTree)) { _ in onToggleFileTree() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleRichInput)) { _ in onToggleRichInput() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleVoiceRecording)) { _ in onToggleVoiceRecording() }
    }
}
