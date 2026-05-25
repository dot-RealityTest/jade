import Foundation

extension Notification.Name {
    static let renameActiveTab = Notification.Name("MuxyRenameActiveTab")
    static let toggleThemePicker = Notification.Name("MuxyToggleThemePicker")
    static let themeDidChange = Notification.Name("MuxyThemeDidChange")
    static let findInTerminal = Notification.Name("MuxyFindInTerminal")
    static let openVCSWindow = Notification.Name("MuxyOpenVCSWindow")
    static let openHelpWindow = Notification.Name("MuxyOpenHelpWindow")
    static let toggleAttachedVCS = Notification.Name("MuxyToggleAttachedVCS")
    static let toggleFileTree = Notification.Name("MuxyToggleFileTree")
    static let refocusActiveTerminal = Notification.Name("MuxyRefocusActiveTerminal")
    static let quickOpen = Notification.Name("MuxyQuickOpen")
    static let commandPalette = Notification.Name("MuxyCommandPalette")
    static let findInFiles = Notification.Name("MuxyFindInFiles")
    static let switchWorktree = Notification.Name("MuxySwitchWorktree")
    static let openProjectPicker = Notification.Name("MuxyOpenProjectPicker")
    static let focusProjectPickerDefaultLocation = Notification.Name("MuxyFocusProjectPickerDefaultLocation")
    static let saveActiveEditor = Notification.Name("MuxySaveActiveEditor")
    static let windowFullScreenDidChange = Notification.Name("MuxyWindowFullScreenDidChange")
    static let toggleSidebar = Notification.Name("MuxyToggleSidebar")
    static let toggleNotificationPanel = Notification.Name("MuxyToggleNotificationPanel")
    static let toggleAIUsage = Notification.Name("MuxyToggleAIUsage")
    static let toggleSnippetsPanel = Notification.Name("MuxyToggleSnippetsPanel")
    static let toggleInspectorPanel = Notification.Name("MuxyToggleInspectorPanel")
    static let toggleProjectNotesPanel = Notification.Name("MuxyToggleProjectNotesPanel")
    static let toggleProjectTodoPanel = Notification.Name("MuxyToggleProjectTodoPanel")
    static let toggleAIAssistant = Notification.Name("MuxyToggleAIAssistant")
    static let focusAIAssistantInput = Notification.Name("MuxyFocusAIAssistantInput")
    static let explainSelectionWithAI = Notification.Name("MuxyExplainSelectionWithAI")
    static let applyAIAssistantCode = Notification.Name("MuxyApplyAIAssistantCode")
    static let vcsRepoDidChange = Notification.Name("MuxyVCSRepoDidChange")
    static let vcsDidRefresh = Notification.Name("MuxyVCSDidRefresh")
    static let externalDragHoverChanged = Notification.Name("MuxyExternalDragHoverChanged")
    static let toggleRichInput = Notification.Name("MuxyToggleRichInput")
    static let toggleVoiceRecording = Notification.Name("MuxyToggleVoiceRecording")
}

enum ExternalDragHoverUserInfoKey {
    static let isHovering = "isHovering"
    static let areaID = "areaID"
}
