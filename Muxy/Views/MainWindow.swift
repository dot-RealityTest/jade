import AppKit
import SwiftUI

enum MainWindowLayout {
    static func leftNavigationWidth(sidebarWidth: CGFloat) -> CGFloat {
        max(0, sidebarWidth)
    }

    static func titleBarNavigationOverlayWidth(
        leftNavigationWidth: CGFloat,
        titleBarNavigationWidth: CGFloat,
        isFullScreen: Bool
    ) -> CGFloat {
        guard !isFullScreen else { return 0 }
        return max(leftNavigationWidth, titleBarNavigationWidth)
    }

    static func mainTitleBarLeadingInset(
        leftNavigationWidth: CGFloat,
        titleBarNavigationOverlayWidth: CGFloat,
        isFullScreen: Bool
    ) -> CGFloat {
        guard !isFullScreen else { return 0 }
        return max(0, titleBarNavigationOverlayWidth - leftNavigationWidth)
    }
}

struct MainWindow: View {
    @Environment(AppState.self) private var appState
    @Environment(ProjectStore.self) private var projectStore
    @Environment(WorktreeStore.self) private var worktreeStore
    @Environment(GhosttyService.self) private var ghostty
    @Environment(\.openWindow) private var openWindow
    @State private var dragCoordinator = TabDragCoordinator()
    private enum AttachedVCSLayout {
        static let minWidth: CGFloat = 200
        static let defaultWidth: CGFloat = 400
        static let maxWidth: CGFloat = 800
    }

    private enum FileTreeLayout {
        static let minWidth: CGFloat = 180
        static let defaultWidth: CGFloat = 260
        static let maxWidth: CGFloat = 600
    }

    private enum RichInputPanelLayout {
        static let minWidth: CGFloat = 280
        static let defaultWidth: CGFloat = 380
        static let maxWidth: CGFloat = 800
        static let minHeight: CGFloat = 120
        static let defaultHeight: CGFloat = 220
        static let maxHeight: CGFloat = 600
    }

    private enum SidePanelKind {
        case vcs
        case fileTree
    }

    private enum CloseConfirmationKind {
        case lastTab
        case unsavedEditor
        case runningProcess

        var title: String {
            switch self {
            case .lastTab:
                "Close Project?"
            case .unsavedEditor:
                "Save Changes Before Closing?"
            case .runningProcess:
                "Close Tab?"
            }
        }

        var message: String {
            switch self {
            case .lastTab:
                "This is the last tab. Closing it will remove the project from the sidebar."
            case .unsavedEditor:
                "This file has unsaved changes. If you don't save, your changes will be lost."
            case .runningProcess:
                "A process is still running in this tab. Are you sure you want to close it?"
            }
        }
    }

    @State private var vcsPanelVisible = false
    @State private var vcsPanelWidth: CGFloat = AttachedVCSLayout.defaultWidth
    @State private var fileTreePanelVisible = false
    @AppStorage("muxy.fileTreeWidth") private var fileTreePanelWidth: Double = .init(FileTreeLayout.defaultWidth)
    @State private var fileTreeStates: [WorktreeKey: FileTreeState] = [:]
    @State private var fileTreeLastTerminalPaths: [WorktreeKey: String] = [:]
    @AppStorage(GeneralSettingsKeys.fileTreeSource) private var fileTreeSourceRaw = FileTreeSourcePreference.defaultValue.rawValue
    @State private var richInputPanelVisible = false
    @State private var richInputMode: RichInputPanelMode = .send
    @State private var panelToRestoreAfterRichInput: SidePanelKind?
    @AppStorage("muxy.richInputPanelWidth") private var richInputPanelWidth: Double = .init(RichInputPanelLayout.defaultWidth)
    @AppStorage("muxy.richInputPanelHeight") private var richInputPanelHeight: Double = .init(RichInputPanelLayout.defaultHeight)
    @AppStorage(RichInputPreferences.fontSizeKey) private var richInputFontSize: Double = RichInputPreferences.defaultFontSize
    @AppStorage(RichInputPreferences.floatingKey) private var richInputFloating = RichInputPreferences.defaultFloating
    @AppStorage(RichInputPreferences.positionKey) private var richInputPosition: RichInputPanelPosition = RichInputPreferences
        .defaultPosition
    @AppStorage(RichInputPreferences.broadcastKey) private var richInputBroadcast = RichInputPreferences.defaultBroadcast
    @State private var richInputStates: [WorktreeKey: RichInputState] = [:]
    @State private var showQuickOpen = false
    @State private var showFindInFiles = false
    @State private var showWorktreeSwitcher = false
    @State private var showProjectPicker = false
    @State private var overlayAnimatingOut = false
    @State private var snippetsPanelVisible = UserDefaults.standard.bool(forKey: "muxy.snippetsPanelVisible")
    @State private var snippetsScopePreferences = SnippetsScopePreferences.shared
    @State private var notesPanelVisible = UserDefaults.standard.bool(forKey: "muxy.notesPanelVisible")
        || UserDefaults.standard.bool(forKey: "muxy.inspectorPanelVisible")
    @State private var todoPanelVisible = UserDefaults.standard.bool(forKey: "muxy.todoPanelVisible")
        || UserDefaults.standard.bool(forKey: "muxy.inspectorPanelVisible")
    @State private var projectInspectorStore = ProjectInspectorStore.shared
    @State private var remoteSpacesStore = RemoteSpacesStore.shared
    @State private var showCommandPalette = false
    @State private var showRichInputPreview = false
    @State private var showThemePicker = false
    @State private var showNotificationPanel = false
    @State private var showLocalPorts = false
    @State private var pendingJourneyProposal: JourneyStepProposal?
    @State private var showJourneyStepReview = false
    @AppStorage("muxy.aiAssistantPanelVisible") private var aiAssistantPanelVisible = false
    @State private var mainWindowWidth: CGFloat = WindowLayoutMetrics.mainDefaultWidth
    @State private var isFullScreen = false
    @AppStorage("muxy.sidebarExpanded") private var sidebarExpanded = false
    @AppStorage("muxy.showStatusBar") private var showStatusBar = true
    @AppStorage(SidebarCollapsedStyle.storageKey) private var sidebarCollapsedStyleRaw = SidebarCollapsedStyle.defaultValue.rawValue
    @AppStorage(SidebarExpandedStyle.storageKey) private var sidebarExpandedStyleRaw = SidebarExpandedStyle.defaultValue.rawValue
    @AppStorage("muxy.notifications.toastPosition") private var toastPositionRaw = ToastPosition.topCenter.rawValue
    @AppStorage(RecordingPreferences.autoSendKey) private var recordingAutoSend = RecordingPreferences.defaultAutoSend
    @AppStorage(RecordingPreferences.languageKey) private var recordingLanguage = RecordingPreferences.defaultLanguage
    @State private var voiceRecording = VoiceRecordingState.shared
    @MainActor private var trafficLightWidth: CGFloat { UIMetrics.scaled(75) }

    var body: some View {
        applyMainWindowLifecycle(to: mainWindowChrome)
    }

    private var mainWindowChrome: some View {
        mainWindowChromeContent
    }

    private var mainWindowChromeContent: some View {
        HStack(spacing: 0) {
            leftNavigationColumn
            mainWorkspaceColumn
        }
        .background {
            GeometryReader { geometry in
                Color.clear
                    .onAppear { mainWindowWidth = geometry.size.width }
                    .onChange(of: geometry.size.width) { _, width in
                        mainWindowWidth = width
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sidebarExpanded)
        .overlay(alignment: .topLeading) {
            titleBarNavigationOverlay
        }
        .environment(
            \.overlayActive,
            showQuickOpen || showFindInFiles || showWorktreeSwitcher || showProjectPicker || overlayAnimatingOut || showCommandPalette ||
                showRichInputPreview || showThemePicker || showNotificationPanel || showLocalPorts || voiceRecording.isPanelVisible ||
                showJourneyStepReview
        )
        .overlay(alignment: .bottom) {
            if voiceRecording.isPanelVisible {
                VoiceRecordingPanel(state: voiceRecording, autoSend: recordingAutoSend)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: voiceRecording.isPanelVisible)
        .overlay(alignment: toastAlignment) {
            if let toast = ToastState.shared.message {
                HStack(spacing: UIMetrics.spacing3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: UIMetrics.fontBody, weight: .semibold))
                        .foregroundStyle(MuxyTheme.diffAddFg)
                    Text(toast)
                        .font(.system(size: UIMetrics.fontBody, weight: .medium))
                        .foregroundStyle(MuxyTheme.fg)
                }
                .padding(.horizontal, UIMetrics.scaled(14))
                .padding(.vertical, UIMetrics.spacing4)
                .background(MuxyTheme.bg, in: Capsule())
                .overlay(Capsule().stroke(MuxyTheme.border, lineWidth: 1))
                .padding(toastEdgePadding)
                .transition(.move(edge: toastTransitionEdge).combined(with: .opacity))
                .allowsHitTesting(false)
                .accessibilityLabel(toast)
                .accessibilityAddTraits(.isStaticText)
            }
        }
        .overlay {
            mainWindowModalOverlays
        }
        .animation(.easeInOut(duration: 0.15), value: showQuickOpen)
        .animation(.easeInOut(duration: 0.15), value: showFindInFiles)
        .animation(.easeInOut(duration: 0.15), value: showWorktreeSwitcher)
        .animation(.easeInOut(duration: 0.15), value: showProjectPicker)
        .modifier(OverlayExitTracker(
            showQuickOpen: showQuickOpen,
            showFindInFiles: showFindInFiles,
            showWorktreeSwitcher: showWorktreeSwitcher,
            showProjectPicker: showProjectPicker,
            onAnimatingOut: { overlayAnimatingOut = $0 }
        ))
        .animation(.easeInOut(duration: 0.2), value: ToastState.shared.message != nil)
        .coordinateSpace(name: DragCoordinateSpace.mainWindow)
        .environment(dragCoordinator)
        .background(MainWindowShortcutInterceptor(
            onShortcut: { action in handleShortcutAction(action) },
            onCommandShortcut: { shortcut in handleCommandShortcut(shortcut) },
            onMouseBack: { appState.goBack() },
            onMouseForward: { appState.goForward() }
        ))
        .background(WindowConfigurator(configVersion: ghostty.configVersion, uiScalePreset: UIScale.shared.preset))
        .background(WindowTitleUpdater(title: windowTitle))
        .ignoresSafeArea(.container, edges: .top)
    }

    private func applyMainWindowLifecycle(to content: some View) -> some View {
        applyMainWindowStateObservers(to: content.modifier(mainWindowNotificationHandlers))
    }

    private var mainWindowNotificationHandlers: MainWindowNotificationHandlers {
        MainWindowNotificationHandlers(
            showQuickOpen: $showQuickOpen,
            showFindInFiles: $showFindInFiles,
            showWorktreeSwitcher: $showWorktreeSwitcher,
            showProjectPicker: $showProjectPicker,
            sidebarExpanded: $sidebarExpanded,
            isFullScreen: $isFullScreen,
            showCommandPalette: $showCommandPalette,
            showThemePicker: $showThemePicker,
            showNotificationPanel: $showNotificationPanel,
            aiAssistantPanelVisible: $aiAssistantPanelVisible,
            openWindow: openWindow,
            onToggleSnippetsPanel: toggleSnippetsPanel,
            onToggleNotesPanel: toggleNotesPanel,
            onToggleTodoPanel: toggleTodoPanel,
            onToggleAIAssistantPanel: toggleAIAssistantPanel,
            onToggleAttachedVCS: toggleAttachedVCSPanel,
            onToggleFileTree: toggleFileTreePanel,
            onToggleRichInput: toggleRichInputPanel,
            onToggleRichInputPreview: toggleRichInputPreview,
            onToggleVoiceRecording: { _ = openVoiceRecorder() },
            onSendToObsidian: sendToObsidian,
            onRunObsidianMCPTool: performObsidianMCPTool,
            onPromptObsidianSearch: promptObsidianSearch,
            onExplainSelection: handleExplainSelection,
            onApplyAIAssistantCode: handleApplyAIAssistantCode
        )
    }

    private func applyMainWindowStateObservers(to content: some View) -> some View {
        content
            .onChange(of: vcsPruneSignature) { pruneFileTreeStates() }
            .onChange(of: vcsEnsureSignature) { handleVCSEnsureSignatureChange() }
            .modifier(FileTreeSourceObserver(
                activeTerminalCWD: activeTerminalPane?.currentWorkingDirectory,
                activeTerminalID: activeTerminalPane?.id,
                sourceRaw: fileTreeSourceRaw,
                onTerminalChange: refreshFileTreeRootForActiveTerminal,
                onSourceChange: handleFileTreeSourceChange
            ))
            .modifier(FileTreeSelectionSync(
                filePath: activeEditorFilePath,
                panelVisible: fileTreePanelVisible,
                sync: syncFileTreeSelection
            ))
            .onChange(of: appState.pendingLastTabClose != nil) { _, isPresented in
                guard isPresented else { return }
                presentCloseConfirmation(.lastTab)
            }
            .onChange(of: appState.pendingUnsavedEditorTabClose != nil) { _, isPresented in
                guard isPresented else { return }
                presentCloseConfirmation(.unsavedEditor)
            }
            .onChange(of: appState.pendingProcessTabClose != nil) { _, isPresented in
                guard isPresented else { return }
                presentCloseConfirmation(.runningProcess)
            }
            .onChange(of: appState.pendingSaveErrorMessage != nil) { _, isPresented in
                guard isPresented, let message = appState.pendingSaveErrorMessage else { return }
                presentSaveErrorAlert(message: message)
            }
            .onChange(of: appState.pendingLayoutApply != nil) { _, isPresented in
                guard isPresented, let pending = appState.pendingLayoutApply else { return }
                presentLayoutApplyConfirmation(pending: pending)
            }
            .modifier(RemoteSpaceThemeSync(
                projectID: appState.activeProjectID,
                activeSpace: activeRemoteSpace
            ))
            .onAppear { syncProjectInspectorStore() }
            .onChange(of: appState.activeProjectID) { syncProjectInspectorStore() }
            .modifier(SentryConsentPrompter())
    }

    private func handleVCSEnsureSignatureChange() {
        guard let project = activeProject else { return }
        if fileTreePanelVisible {
            ensureFileTreeState(for: project)
        }
    }

    private func handleFileTreeSourceChange() {
        guard let project = activeProject else { return }
        ensureFileTreeState(for: project)
    }

    @ViewBuilder
    private var mainWindowModalOverlays: some View {
        if showQuickOpen, let project = activeProject {
            QuickOpenOverlay(
                projectPath: activeWorktreePath(for: project),
                onSelect: { filePath in
                    showQuickOpen = false
                    appState.openFile(filePath, projectID: project.id)
                },
                onDismiss: { showQuickOpen = false }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showFindInFiles, let project = activeProject {
            FindInFilesOverlay(
                projectPath: activeWorktreePath(for: project),
                onSelect: { match in
                    showFindInFiles = false
                    appState.openFile(
                        match.absolutePath,
                        projectID: project.id,
                        line: match.lineNumber,
                        column: match.column
                    )
                },
                onDismiss: { showFindInFiles = false }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showWorktreeSwitcher {
            OpenerOverlay(
                items: openerItems,
                recents: openerRecentItems,
                activeWorktreeKey: activeWorktreeKey,
                onSelect: { item in
                    showWorktreeSwitcher = false
                    handleOpenerSelection(item)
                },
                onDismiss: { showWorktreeSwitcher = false }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showProjectPicker {
            ProjectPickerOverlay(
                projectPaths: projectStore.projects.map(\.path),
                onConfirm: { path, createIfMissing in
                    ProjectOpenService.confirmProjectPathResult(
                        path,
                        appState: appState,
                        projectStore: projectStore,
                        worktreeStore: worktreeStore,
                        createIfMissing: createIfMissing
                    )
                },
                onChooseFinder: {
                    ProjectOpenService.openProject(
                        appState: appState,
                        projectStore: projectStore,
                        worktreeStore: worktreeStore
                    )
                },
                onDismiss: { showProjectPicker = false }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showCommandPalette {
            CommandPaletteOverlay(
                appItems: commandPaletteAppItems,
                remoteSpaces: remoteSpacesStore.spaces,
                activeRemoteSpace: activeRemoteSpace,
                snippetScope: activeSnippetScope,
                projectPath: activeCommandPaletteProjectPath,
                worktreeOpenerItems: worktreeOpenerItems,
                naturalCommandContext: activeNaturalCommandContext,
                onSelect: selectCommandPaletteItem,
                onRunNaturalCommand: runNaturalCommandPlan,
                onSaveNaturalCommand: saveNaturalCommandPlan,
                onDismiss: dismissCommandPalette
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showJourneyStepReview, let proposal = pendingJourneyProposal, let project = activeProject {
            JourneyStepReviewOverlay(
                proposal: proposal,
                projectName: project.name,
                onConfirm: { overrideBlocker in
                    confirmJourneyStep(proposal, project: project, overrideBlocker: overrideBlocker)
                },
                onNotNow: {
                    skipJourneyStep(proposal, project: project)
                },
                onCancel: {
                    cancelJourneyStep(proposal, project: project)
                }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showRichInputPreview, let project = activeProject {
            RichInputPreviewOverlay(
                projectName: project.name,
                markdown: projectInspectorStore.workspaceMarkdown,
                onToggleTask: { lineIndex in
                    toggleRichInputPreviewTask(lineIndex: lineIndex)
                },
                onCopyAll: {
                    copyRichInputPreviewText(projectInspectorStore.workspaceMarkdown)
                },
                onCopyLine: { line in
                    copyRichInputPreviewText(line.copyText)
                },
                onDismiss: { showRichInputPreview = false }
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showThemePicker {
            UtilityOverlay(onDismiss: { showThemePicker = false }, content: {
                ThemePicker(mode: .sidebar)
                    .frame(width: UIMetrics.utilityOverlayWidth, height: UIMetrics.themePickerOverlayHeight)
            })
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showNotificationPanel {
            UtilityOverlay(onDismiss: { showNotificationPanel = false }, content: {
                NotificationPanel(onDismiss: { showNotificationPanel = false })
                    .frame(width: UIMetrics.utilityOverlayWidth, height: UIMetrics.utilityOverlayHeight)
            })
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }

        if showLocalPorts {
            UtilityOverlay(onDismiss: { showLocalPorts = false }, content: {
                LocalPortsPanel(onDismiss: { showLocalPorts = false })
            })
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private var leftNavigationColumn: some View {
        VStack(spacing: 0) {
            if !isFullScreen {
                Color.clear
                    .frame(height: UIMetrics.titleBarHeight)
                    .background(WindowDragRepresentable())

                Rectangle().fill(MuxyTheme.border).frame(height: 1)
                    .accessibilityHidden(true)
            }

            Sidebar(expanded: sidebarExpanded)
        }
        .frame(width: leftNavigationWidth, alignment: .leading)
        .clipped()
        .background(MuxyTheme.bg)
        .overlay(alignment: .trailing) {
            if leftNavigationWidth > 0 {
                Rectangle().fill(MuxyTheme.border)
                    .frame(width: 1)
                    .padding(.top, leftNavigationBorderTopPadding)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(.easeInOut(duration: 0.2), value: leftNavigationWidth)
    }

    private var mainWorkspaceColumn: some View {
        VStack(spacing: 0) {
            mainTitleBarContent
                .frame(height: UIMetrics.titleBarHeight)
                .background(WindowDragRepresentable())
                .background(MuxyTheme.bg)

            Rectangle().fill(MuxyTheme.border).frame(height: 1)
                .background(MuxyTheme.bg)

            workspaceContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mainTitleBarContent: some View {
        HStack(spacing: 0) {
            if mainTitleBarLeadingInset > 0 {
                Color.clear
                    .frame(width: mainTitleBarLeadingInset)
                    .fixedSize(horizontal: true, vertical: false)
            }

            topBarContent
        }
        .animation(.easeInOut(duration: 0.2), value: mainTitleBarLeadingInset)
    }

    @ViewBuilder
    private var titleBarNavigationOverlay: some View {
        if !isFullScreen {
            Color.clear
                .frame(width: titleBarNavigationOverlayWidth, height: UIMetrics.titleBarHeight)
                .fixedSize(horizontal: true, vertical: false)
                .background(WindowDragRepresentable())
                .background(MuxyTheme.bg)
                .overlay(alignment: .trailing) {
                    HStack(spacing: 0) {
                        navigationArrows
                        if titleBarNavigationOverflowsSidebar {
                            Rectangle().fill(MuxyTheme.border).frame(width: 1)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: titleBarNavigationOverlayWidth)
        }
    }

    private var workspaceContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ZStack {
                    MuxyTheme.bg
                    if let project = activeProject,
                       appState.workspaceRoot(for: project.id) == nil,
                       let worktree = resolvedActiveWorktree(for: project)
                    {
                        EmptyProjectPlaceholder(project: project) {
                            appState.selectWorktree(projectID: project.id, worktree: worktree)
                        }
                    } else if projectsWithWorkspaces.isEmpty {
                        WelcomeView()
                    } else if let project = activeProjectWithWorkspace,
                              let activeKey = appState.activeWorktreeKey(for: project.id)
                    {
                        ForEach(mountedWorktreeKeys(for: project), id: \.self) { key in
                            TerminalArea(
                                project: project,
                                worktreeKey: key,
                                isActiveProject: key == activeKey
                            )
                            .opacity(key == activeKey ? 1 : 0)
                            .allowsHitTesting(key == activeKey)
                            .zIndex(key == activeKey ? 1 : 0)
                        }
                    }
                }

                rightSidePanel
                snippetsSidePanel
                aiAssistantSidePanel
            }
            .overlay(alignment: .trailing) {
                floatingRichInputOverlay
            }
            .overlay(alignment: .bottom) {
                floatingBottomRichInputOverlay
            }
            .animation(.easeInOut(duration: 0.2), value: richInputPanelVisible)

            bottomDockedRichInputPanel

            if showStatusBar {
                ProjectStatusBar(
                    activePane: activeTerminalPane,
                    activeWorktree: activeProject.flatMap { resolvedActiveWorktree(for: $0) },
                    isInteractive: activeTerminalPane != nil && !overlayAnimatingOut,
                    richInputVisible: richInputPanelVisible,
                    richInputFontSize: $richInputFontSize
                )
            }
        }
    }

    private var navigationArrows: some View {
        HStack(spacing: UIMetrics.spacing1) {
            NavigationArrowButton(
                symbol: "chevron.left",
                isEnabled: appState.navigation.canGoBack,
                label: "Back (\(KeyBindingStore.shared.combo(for: .navigateBack).displayString))"
            ) {
                appState.goBack()
            }
            NavigationArrowButton(
                symbol: "chevron.right",
                isEnabled: appState.navigation.canGoForward,
                label: "Forward (\(KeyBindingStore.shared.combo(for: .navigateForward).displayString))"
            ) {
                appState.goForward()
            }
        }
        .padding(.trailing, UIMetrics.spacing2)
    }

    @ViewBuilder
    private var topBarContent: some View {
        if let project = activeProject,
           let root = appState.workspaceRoot(for: project.id),
           case let .tabArea(area) = root
        {
            PaneTabStrip(
                areaID: area.id,
                tabs: PaneTabStrip.snapshots(from: area.tabs),
                activeTabID: area.activeTabID,
                isFocused: true,
                isWindowTitleBar: true,
                showVCSButton: true,
                showDevelopmentBadge: AppEnvironment.isDevelopment,
                openInIDEProjectPath: activeWorktreePath(for: project),
                openInIDEFilePath: area.activeTab?.content.editorState?.filePath,
                openInIDECursorProvider: {
                    guard let editorState = appState.activeTab(for: project.id)?.content.editorState else {
                        return (nil, nil)
                    }
                    return (editorState.cursorLine, editorState.cursorColumn)
                },
                projectID: project.id,
                onSelectTab: { tabID in
                    appState.dispatch(.selectTab(projectID: project.id, areaID: area.id, tabID: tabID))
                },
                onCreateTab: {
                    appState.dispatch(.createTab(projectID: project.id, areaID: area.id))
                },
                onCreateVCSTab: {
                    openVCS(for: project, preferredAreaID: area.id)
                },
                onCloseTab: { tabID in
                    appState.closeTab(tabID, areaID: area.id, projectID: project.id)
                },
                onCloseOtherTabs: { tabID in
                    for id in area.tabs.filter({ $0.id != tabID && !$0.isPinned }).map(\.id) {
                        appState.closeTab(id, areaID: area.id, projectID: project.id)
                    }
                },
                onCloseTabsToLeft: { tabID in
                    guard let index = area.tabs.firstIndex(where: { $0.id == tabID }) else { return }
                    for id in area.tabs.prefix(index).filter({ !$0.isPinned }).map(\.id) {
                        appState.closeTab(id, areaID: area.id, projectID: project.id)
                    }
                },
                onCloseTabsToRight: { tabID in
                    guard let index = area.tabs.firstIndex(where: { $0.id == tabID }) else { return }
                    for id in area.tabs.suffix(from: index + 1).filter({ !$0.isPinned }).map(\.id) {
                        appState.closeTab(id, areaID: area.id, projectID: project.id)
                    }
                },
                onSplit: { dir in
                    appState.dispatch(.splitArea(.init(
                        projectID: project.id,
                        areaID: area.id,
                        direction: dir,
                        position: .second
                    )))
                },
                onDropAction: { result in
                    appState.dispatch(result.action(projectID: project.id))
                },
                workspaceChromePanelState: workspaceChromePanelState,
                workspaceChromeHandlers: workspaceChromeHandlers,
                onCreateTabAdjacent: { tabID, side in
                    area.createTabAdjacent(to: tabID, side: side)
                },
                onTogglePin: { tabID in
                    area.togglePin(tabID)
                },
                onSetCustomTitle: { tabID, title in
                    area.setCustomTitle(tabID, title: title)
                    appState.saveWorkspaces()
                },
                onSetColorID: { tabID, colorID in
                    area.setColorID(tabID, colorID: colorID)
                    appState.saveWorkspaces()
                },
                onReorderTab: { fromOffsets, toOffset in
                    area.reorderTab(fromOffsets: fromOffsets, toOffset: toOffset)
                }
            )
        } else {
            WindowDragRepresentable(alwaysEnabled: true)
                .overlay {
                    HStack {
                        if let project = activeProject {
                            Text(project.name)
                                .font(.system(size: UIMetrics.fontBody, weight: .semibold))
                                .foregroundStyle(MuxyTheme.fgMuted)
                                .padding(.leading, UIMetrics.spacing6)
                        }
                        Spacer(minLength: 0)
                    }
                    .allowsHitTesting(false)
                }
                .overlay(alignment: .trailing) {
                    if let project = activeProject {
                        WorkspaceChromeTrailingActions(
                            layoutPickerProjectID: project.id,
                            openInIDEProjectPath: activeWorktreePath(for: project),
                            openInIDEFilePath: activeEditorFilePath,
                            openInIDECursorProvider: activeEditorCursor,
                            panelState: workspaceChromePanelState,
                            showsSplitActions: true,
                            showVCSButton: true,
                            showDevelopmentBadge: AppEnvironment.isDevelopment,
                            showMaximizeButton: false,
                            isMaximized: false,
                            onSplit: { direction in
                                guard let area = appState.focusedArea(for: project.id) else { return }
                                appState.dispatch(.splitArea(.init(
                                    projectID: project.id,
                                    areaID: area.id,
                                    direction: direction,
                                    position: .second
                                )))
                            },
                            onCreateTab: {
                                appState.dispatch(.createTab(projectID: project.id, areaID: nil))
                            },
                            onCreateVCSTab: {
                                openVCS(for: project)
                            },
                            onQuickOpen: { showQuickOpen.toggle() },
                            onToggleFileTree: toggleFileTreePanel,
                            onToggleSnippets: toggleSnippetsPanel,
                            onToggleAIAssistant: toggleAIAssistantPanel,
                            onToggleMaximize: nil
                        )
                        .padding(.trailing, UIMetrics.spacing2)
                    }
                }
        }
    }

    @ViewBuilder
    private var snippetsSidePanel: some View {
        if snippetsPanelVisible, !narrowLayoutAdjustments.hideSnippets {
            SnippetsPanel(scope: activeSnippetScope)
        }
    }

    @ViewBuilder
    private var aiAssistantSidePanel: some View {
        if aiAssistantPanelVisible, !narrowLayoutAdjustments.hideAI {
            AIAssistantPanel(
                projectID: appState.activeProjectID,
                projectPath: activeProject.map { activeWorktreePath(for: $0) },
                worktreeID: activeWorktreeKey?.worktreeID,
                worktreePath: activeProject.map { activeWorktreePath(for: $0) },
                activeFile: anyOpenEditorFilePath
            )
        }
    }

    private var worktreeOpenerItems: [OpenerItem] {
        openerItems.filter {
            if case .worktree = $0 { return true }
            return false
        }
    }

    private var workspaceChromePanelState: WorkspaceChromePanelState {
        let adjustments = narrowLayoutAdjustments
        return WorkspaceChromePanelState(
            snippetsVisible: snippetsPanelVisible,
            snippetsSuppressed: adjustments.hideSnippets,
            aiVisible: aiAssistantPanelVisible,
            aiSuppressed: adjustments.hideAI
        )
    }

    private var workspaceChromeHandlers: WorkspaceChromeHandlers {
        WorkspaceChromeHandlers(
            onQuickOpen: { showQuickOpen.toggle() },
            onToggleFileTree: toggleFileTreePanel,
            onToggleSnippets: toggleSnippetsPanel,
            onToggleAIAssistant: toggleAIAssistantPanel
        )
    }

    private var narrowLayoutAdjustments: WindowLayoutMetrics.NarrowWidthAdjustments {
        WindowLayoutMetrics.narrowWidthAdjustments(
            windowWidth: mainWindowWidth,
            sidebarWidth: WindowLayoutMetrics.sidebarWidth(
                expanded: sidebarExpanded,
                collapsedStyle: sidebarCollapsedStyle,
                expandedStyle: sidebarExpandedStyle
            ),
            visibility: auxiliaryPanelVisibility
        )
    }

    private var auxiliaryPanelVisibility: WindowLayoutMetrics.AuxiliaryVisibility {
        WindowLayoutMetrics.AuxiliaryVisibility(
            vcsVisible: vcsPanelVisible && VCSDisplayMode.current == .attached,
            vcsWidth: vcsPanelWidth,
            fileTreeVisible: fileTreePanelVisible,
            fileTreeWidth: CGFloat(fileTreePanelWidth),
            snippetsVisible: snippetsPanelVisible,
            aiVisible: aiAssistantPanelVisible,
            notesVisible: false,
            todoVisible: false
        )
    }

    private var commandPaletteAppItems: [CommandPaletteItem] {
        [
            commandItem(
                .newTab,
                symbolName: "plus.square",
                subtitle: "Create a new terminal tab",
                aliases: ["shell", "terminal"],
                sortPriority: 0
            ),
            commandItem(
                .splitRight,
                symbolName: "rectangle.split.2x1",
                subtitle: "Split the focused pane to the right",
                aliases: ["pane", "layout", "right"],
                sortPriority: 1
            ),
            commandItem(
                .splitDown,
                symbolName: "rectangle.split.1x2",
                subtitle: "Split the focused pane down",
                aliases: ["pane", "layout", "below", "bottom"],
                sortPriority: 2
            ),
            commandItem(
                .openProject,
                symbolName: "folder",
                subtitle: "Open a project folder",
                aliases: ["folder", "workspace"],
                sortPriority: 10
            ),
            CommandPaletteItem(
                id: "journey-initialize",
                title: "Set Up Project Log",
                subtitle: "Create .jade scaffold and project markdown when missing",
                symbolName: "map",
                section: .app,
                searchText: "log session project bootstrap rules md obsidian goals todo project-map setup",
                target: .journeyInitialize,
                sortPriority: 8
            ),
            CommandPaletteItem(
                id: "journey-next-step",
                title: "Confirm Next Step",
                subtitle: "Review focus from todo.md, goals.md, or .jade/journey.md",
                symbolName: "arrow.right.circle",
                section: .app,
                searchText: "log next step confirm session todo goals project markdown focus",
                target: .journeyNextStep,
                sortPriority: 9
            ),
            CommandPaletteItem(
                id: "journey-complete-step",
                title: "Complete Step",
                subtitle: "Mark the current step done and log the session to Obsidian",
                symbolName: "checkmark.seal",
                section: .app,
                searchText: "log complete done step session obsidian achievement",
                target: .journeyCompleteStep,
                sortPriority: 9
            ),
            commandItem(
                .switchWorktree,
                symbolName: "arrow.triangle.branch",
                subtitle: "Switch project worktree",
                aliases: ["branch", "workspace", "git"],
                sortPriority: 11
            ),
        ] + snippetsScopePaletteItems + [
            commandItem(
                .toggleSnippetsScope,
                symbolName: "curlybraces",
                subtitle: snippetsScopeToggleSubtitle,
                aliases: ["snippet scope", "general", "project", "snippets mode"],
                sortPriority: 19
            ),
            commandItem(
                .toggleSnippetsPanel,
                symbolName: "curlybraces",
                subtitle: "Show or hide snippets",
                aliases: ["commands", "vault", "scripts", "shell", "snippets"],
                sortPriority: 20
            ),
            commandItem(
                .toggleAIAssistant,
                symbolName: "bubble.left.and.bubble.right.fill",
                subtitle: "Show or hide the AI assistant",
                aliases: ["ai", "chat", "claude", "assistant", "ask"],
                sortPriority: 21
            ),
            commandItem(
                .toggleRichInput,
                symbolName: "text.bubble",
                subtitle: "Open Rich Input for notes, tasks, and captures",
                aliases: ["rich input", "notes", "tasks", "capture", "send"],
                sortPriority: 22
            ),
            commandItem(
                .toggleRichInputPreview,
                symbolName: "eye",
                subtitle: "Quick markdown preview overlay",
                aliases: ["preview", "markdown", "rich input"],
                sortPriority: 23
            ),
            commandItem(
                .jumpToLatestUnread,
                symbolName: "bell.badge",
                subtitle: "Jump to the latest unread session in this project",
                aliases: ["notification", "unread", "attention", "session", "agent"],
                sortPriority: 6
            ),
            commandItem(
                .toggleNotificationPanel,
                symbolName: "bell",
                subtitle: "Show project session notifications",
                aliases: ["notifications", "alerts", "messages"],
                sortPriority: 7
            ),
            commandItem(
                .quickOpen,
                symbolName: "doc.text.magnifyingglass",
                subtitle: "Search files in the current project",
                aliases: ["files", "open", "finder", "go to file"],
                sortPriority: 30
            ),
            commandItem(
                .findInFiles,
                symbolName: "text.magnifyingglass",
                subtitle: "Search file contents in the current project",
                aliases: ["grep", "search", "text", "content"],
                sortPriority: 31
            ),
            commandItem(
                .openVCSTab,
                symbolName: "point.3.connected.trianglepath.dotted",
                subtitle: "Open source control",
                aliases: ["git", "vcs", "changes", "commit", "diff"],
                sortPriority: 32
            ),
            commandItem(
                .toggleFileTree,
                symbolName: "sidebar.left",
                subtitle: "Show or hide the file tree",
                aliases: ["files", "finder", "explorer", "sidebar", "tree"],
                sortPriority: 33
            ),
            commandItem(
                .toggleSidebar,
                symbolName: "sidebar.leading",
                subtitle: "Show or hide the project sidebar",
                aliases: ["projects", "sidebar", "navigation"],
                sortPriority: 34
            ),
            commandItem(
                .toggleThemePicker,
                symbolName: "paintpalette",
                subtitle: "Open the theme picker",
                aliases: ["appearance", "colors", "theme"],
                sortPriority: 50
            ),
            commandItem(
                .toggleAIUsage,
                symbolName: "chart.bar",
                subtitle: "Open AI usage",
                aliases: ["tokens", "usage", "cost"],
                sortPriority: 51
            ),
            CommandPaletteItem(
                id: "app-local-ports",
                title: "Local Ports",
                subtitle: "Show active listeners and dead ports from this session",
                symbolName: "network",
                section: .app,
                searchText: "active ports dead ports listening localhost tcp services processes lsof",
                target: .localPorts,
                sortPriority: 52
            ),
        ] + localCommandPaletteItems + [
            commandItem(
                .reloadConfig,
                symbolName: "arrow.clockwise",
                subtitle: "Reload terminal configuration",
                aliases: ["refresh", "ghostty", "config"],
                sortPriority: 53
            ),
        ]
    }

    private var localCommandPaletteItems: [CommandPaletteItem] {
        let ollamaModel = NaturalCommandSettings.shared.ollamaModel
        return LocalCommandPaletteAction.allCases.map { action in
            CommandPaletteItem(
                id: "app-local-\(action.rawValue)",
                title: action.title,
                subtitle: action.subtitle(ollamaModel: ollamaModel),
                symbolName: action.symbolName,
                section: .app,
                searchText: action.searchText,
                target: .localCommand(action),
                sortPriority: action.sortPriority
            )
        }
    }

    private var activeCommandPaletteProjectPath: String? {
        guard let project = activeProject else { return nil }
        return activeWorktreePath(for: project)
    }

    private var activeNaturalCommandContext: NaturalCommandContext {
        if let remoteSpace = activeRemoteSpace {
            return .remote(remoteSpace)
        }
        return .local(projectPath: activeCommandPaletteProjectPath)
    }

    private var snippetsScopeToggleSubtitle: String {
        switch snippetsScopePreferences.mode {
        case .general:
            if activeProject == nil {
                return "Switch to project snippets when a project is open"
            }
            return "Switch to project-specific snippets"
        case .project:
            return "Switch to general snippets shared across projects"
        }
    }

    private var snippetsScopePaletteItems: [CommandPaletteItem] {
        let mode = snippetsScopePreferences.mode
        return [
            CommandPaletteItem(
                id: "snippets-scope-general",
                title: "General Snippets",
                subtitle: mode == .general ? "Active · shared across projects" : "Use snippets for every project",
                symbolName: "curlybraces",
                section: .app,
                searchText: "snippets general shared global scope mode",
                target: .snippetsScope(.general),
                sortPriority: 17
            ),
            CommandPaletteItem(
                id: "snippets-scope-project",
                title: "Project Snippets",
                subtitle: snippetsProjectScopeSubtitle,
                symbolName: "curlybraces",
                section: .app,
                searchText: "snippets project workspace local scope mode",
                target: .snippetsScope(.project),
                sortPriority: 18
            ),
        ]
    }

    private var snippetsProjectScopeSubtitle: String {
        let mode = snippetsScopePreferences.mode
        guard let project = activeProject else {
            return "Select a project first"
        }
        if mode == .project {
            return "Active · \(project.name)"
        }
        return "Use snippets for \(project.name) only"
    }

    private func commandItem(
        _ action: ShortcutAction,
        symbolName: String,
        subtitle: String,
        aliases: [String] = [],
        sortPriority: Int = 0
    ) -> CommandPaletteItem {
        CommandPaletteItem(
            id: "shortcut-\(action.rawValue)",
            title: action.displayName,
            subtitle: subtitle,
            symbolName: symbolName,
            section: .app,
            searchText: ([action.category] + aliases).joined(separator: " "),
            target: .shortcut(action),
            sortPriority: sortPriority
        )
    }

    private var toastPosition: ToastPosition {
        ToastPosition(rawValue: toastPositionRaw) ?? .topCenter
    }

    private var toastAlignment: Alignment {
        switch toastPosition {
        case .topCenter: .top
        case .topRight: .topTrailing
        case .bottomCenter: .bottom
        case .bottomRight: .bottomTrailing
        }
    }

    private var toastEdgePadding: EdgeInsets {
        switch toastPosition {
        case .topCenter: EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 0)
        case .topRight: EdgeInsets(top: 40, leading: 0, bottom: 0, trailing: 16)
        case .bottomCenter: EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0)
        case .bottomRight: EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 16)
        }
    }

    private var toastTransitionEdge: Edge {
        switch toastPosition {
        case .topCenter,
             .topRight: .top
        case .bottomCenter,
             .bottomRight: .bottom
        }
    }

    private var sidebarCollapsedStyle: SidebarCollapsedStyle {
        SidebarCollapsedStyle(rawValue: sidebarCollapsedStyleRaw) ?? .defaultValue
    }

    private var sidebarExpandedStyle: SidebarExpandedStyle {
        SidebarExpandedStyle(rawValue: sidebarExpandedStyleRaw) ?? .defaultValue
    }

    private var sidebarResolvedWidth: CGFloat {
        SidebarLayout.resolvedWidth(
            expanded: sidebarExpanded,
            collapsedStyle: sidebarCollapsedStyle,
            expandedStyle: sidebarExpandedStyle
        )
    }

    private var leftNavigationWidth: CGFloat {
        MainWindowLayout.leftNavigationWidth(sidebarWidth: sidebarResolvedWidth)
    }

    private var titleBarNavigationOverlayWidth: CGFloat {
        MainWindowLayout.titleBarNavigationOverlayWidth(
            leftNavigationWidth: leftNavigationWidth,
            titleBarNavigationWidth: titleBarNavigationWidth,
            isFullScreen: isFullScreen
        )
    }

    private var mainTitleBarLeadingInset: CGFloat {
        MainWindowLayout.mainTitleBarLeadingInset(
            leftNavigationWidth: leftNavigationWidth,
            titleBarNavigationOverlayWidth: titleBarNavigationOverlayWidth,
            isFullScreen: isFullScreen
        )
    }

    private var titleBarNavigationOverflowsSidebar: Bool {
        titleBarNavigationOverlayWidth > leftNavigationWidth
    }

    private var leftNavigationBorderTopPadding: CGFloat {
        titleBarNavigationOverflowsSidebar ? UIMetrics.titleBarHeight + 1 : 0
    }

    private var titleBarNavigationWidth: CGFloat {
        trafficLightWidth + navigationArrowsWidth
    }

    private var topBarLeadingWidth: CGFloat {
        let sidebarWidth = SidebarLayout.resolvedWidth(
            expanded: sidebarExpanded,
            collapsedStyle: sidebarCollapsedStyle,
            expandedStyle: sidebarExpandedStyle
        ) + 1
        let navigationMinimum = trafficLightWidth + navigationArrowsWidth
        return max(navigationMinimum, sidebarWidth)
    }

    private var navigationArrowsWidth: CGFloat { 52 }

    private var activeWorktreeKey: WorktreeKey? {
        guard let projectID = appState.activeProjectID,
              let worktreeID = appState.activeWorktreeID[projectID]
        else { return nil }
        return WorktreeKey(projectID: projectID, worktreeID: worktreeID)
    }

    private var activeProject: Project? {
        guard let pid = appState.activeProjectID else { return nil }
        return projectStore.projects.first { $0.id == pid }
    }

    private var activeSnippetScope: SnippetScope {
        SnippetScopeResolver.resolve(
            mode: snippetsScopePreferences.mode,
            project: activeProject,
            remoteSpace: activeRemoteSpace
        )
    }

    private var activeRemoteSpace: RemoteSpace? {
        guard let project = activeProject else { return nil }
        return remoteSpacesStore.space(forProjectPath: project.path)
    }

    private var windowTitle: String {
        guard let project = activeProject else { return "Jade" }
        guard let tabTitle = appState.activeTab(for: project.id)?.title,
              !tabTitle.isEmpty
        else { return project.name }
        return "\(project.name) — \(tabTitle)"
    }

    private var activeProjectWithWorkspace: Project? {
        guard let project = activeProject,
              appState.workspaceRoot(for: project.id) != nil
        else { return nil }
        return project
    }

    private func resolvedActiveWorktree(for project: Project) -> Worktree? {
        worktreeStore.preferred(for: project.id, matching: appState.activeWorktreeID[project.id])
    }

    private var shortcutDispatcher: ShortcutActionDispatcher {
        ShortcutActionDispatcher(
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            ghostty: ghostty
        )
    }

    private func mountedWorktreeKeys(for project: Project) -> [WorktreeKey] {
        appState.workspaceRoots.keys
            .filter { $0.projectID == project.id }
            .sorted { $0.worktreeID.uuidString < $1.worktreeID.uuidString }
    }

    private func handleShortcutAction(_ action: ShortcutAction) -> Bool {
        if action == .toggleVoiceRecording {
            return openVoiceRecorder()
        }
        if handleSnippetsScopeShortcut(action) {
            return true
        }
        return shortcutDispatcher.perform(action, activeProject: activeProject) { project in
            openVCS(for: project)
        }
    }

    private func handleSnippetsScopeShortcut(_ action: ShortcutAction) -> Bool {
        switch action {
        case .toggleSnippetsScope:
            toggleSnippetsScope()
            return true
        default:
            return false
        }
    }

    private func toggleSnippetsScope() {
        if snippetsScopePreferences.mode == .general {
            guard activeProject != nil else {
                ToastState.shared.show("Select a project first")
                return
            }
            setSnippetsScopeMode(.project)
            return
        }
        setSnippetsScopeMode(.general)
    }

    private func setSnippetsScopeMode(_ mode: SnippetsScopeMode) {
        if mode == .project, activeProject == nil {
            ToastState.shared.show("Select a project first")
            return
        }
        guard snippetsScopePreferences.mode != mode else { return }
        snippetsScopePreferences.setMode(mode)
        SnippetsStore.shared.selectScope(activeSnippetScope)
        ToastState.shared.show(activeSnippetScope.displayName)
    }

    private func openVoiceRecorder() -> Bool {
        if voiceRecording.isPanelVisible {
            voiceRecording.cancel()
            return true
        }
        voiceRecording.present(languageIdentifier: recordingLanguage)
        return true
    }

    private func handleCommandShortcut(_ shortcut: CommandShortcut) -> Bool {
        guard let projectID = appState.activeProjectID,
              appState.workspaceRoot(for: projectID) != nil,
              !shortcut.trimmedCommand.isEmpty
        else { return false }
        appState.createCommandTab(projectID: projectID, shortcut: shortcut)
        return true
    }

    private func dismissCommandPalette() {
        showCommandPalette = false
    }

    private func selectCommandPaletteItem(_ item: CommandPaletteItem) {
        showCommandPalette = false
        performCommandPaletteItem(item)
    }

    private func performCommandPaletteItem(_ item: CommandPaletteItem) {
        switch item.target {
        case let .shortcut(action):
            if handleShortcutAction(action) {
                return
            }
            ToastState.shared.show(shortcutUnavailableReason(for: action))
        case let .remoteCommand(action):
            performRemoteCommandPaletteAction(action)
        case let .remote(spaceID):
            guard let space = remoteSpacesStore.spaces.first(where: { $0.id == spaceID }) else { return }
            RemoteSpaceLauncher.open(
                space,
                appState: appState,
                projectStore: projectStore,
                worktreeStore: worktreeStore
            )
        case let .snippet(snippetID):
            runSnippetFromPalette(snippetID)
        case let .file(path):
            guard let project = activeProject else { return }
            appState.openFile(path, projectID: project.id)
        case let .worktree(projectID, worktreeID):
            guard let project = projectStore.projects.first(where: { $0.id == projectID }),
                  let worktree = worktreeStore.worktree(projectID: projectID, worktreeID: worktreeID)
            else { return }
            if appState.activeProjectID == projectID {
                appState.selectWorktree(projectID: projectID, worktree: worktree)
            } else {
                appState.selectProject(project, worktree: worktree)
            }
        case .naturalCommand:
            return
        case .localPorts:
            showLocalPorts = true
        case let .localCommand(action):
            runLocalCommandPaletteAction(action)
        case let .obsidianMCPTool(action, query):
            performObsidianMCPTool(action, query: query)
        case .journeyInitialize:
            initializeJourney()
        case .journeyNextStep:
            presentJourneyNextStep()
        case .journeyCompleteStep:
            completeJourneyStep()
        case let .snippetsScope(mode):
            setSnippetsScopeMode(mode)
        }
    }

    private func initializeJourney() {
        guard let project = activeProject else {
            ToastState.shared.show(JadeJourneyError.noProject.localizedDescription)
            return
        }
        let path = activeWorktreePath(for: project)
        do {
            try JadeJourneyBootstrapService.bootstrap(projectPath: path, projectName: project.name)
            ToastState.shared.show("Project log ready (.jade/ + project markdown)")
        } catch {
            ToastState.shared.show(error.localizedDescription)
        }
    }

    private func presentJourneyNextStep() {
        guard let project = activeProject else {
            ToastState.shared.show(JadeJourneyError.noProject.localizedDescription)
            return
        }
        let path = activeWorktreePath(for: project)
        do {
            let proposal = try JadeJourneyReader.loadNextStepProposal(projectPath: path)
            pendingJourneyProposal = proposal
            showJourneyStepReview = true
        } catch {
            ToastState.shared.show(error.localizedDescription)
        }
    }

    private func confirmJourneyStep(_ proposal: JourneyStepProposal, project: Project, overrideBlocker: Bool) {
        showJourneyStepReview = false
        pendingJourneyProposal = nil

        let prefill = "# \(proposal.title)\n\n\(proposal.why)\n"
        if let richInputState = activeRichInputState {
            richInputState.text = prefill
            richInputState.focusVersion += 1
        }
        openRichInputPanel(mode: .send)

        let outcome: JourneySessionOutcome = overrideBlocker ? .overridden : .started
        logJourneySession(
            outcome: outcome,
            proposal: proposal,
            project: project,
            overrideBlocker: overrideBlocker,
            successMessage: overrideBlocker ? "Session logged (override noted)" : "Session logged to Obsidian"
        )
    }

    private func skipJourneyStep(_ proposal: JourneyStepProposal, project: Project) {
        showJourneyStepReview = false
        pendingJourneyProposal = nil
        logJourneySession(
            outcome: .skipped,
            proposal: proposal,
            project: project,
            overrideBlocker: false,
            successMessage: "Step deferred — session logged"
        )
    }

    private func cancelJourneyStep(_ proposal: JourneyStepProposal, project: Project) {
        showJourneyStepReview = false
        pendingJourneyProposal = nil
        logJourneySession(
            outcome: .declined,
            proposal: proposal,
            project: project,
            overrideBlocker: false,
            successMessage: nil
        )
    }

    private func completeJourneyStep() {
        guard let project = activeProject else {
            ToastState.shared.show(JadeJourneyError.noProject.localizedDescription)
            return
        }
        let path = activeWorktreePath(for: project)
        do {
            let proposal = try JadeJourneyReader.loadNextStepProposal(projectPath: path)
            try JadeJourneyProgressService.completeCurrentStep(projectPath: path, proposal: proposal)
            logJourneySession(
                outcome: .completed,
                proposal: proposal,
                project: project,
                overrideBlocker: false,
                successMessage: "Step completed — log updated"
            )
        } catch {
            ToastState.shared.show(error.localizedDescription)
        }
    }

    private func logJourneySession(
        outcome: JourneySessionOutcome,
        proposal: JourneyStepProposal,
        project: Project,
        overrideBlocker: Bool,
        successMessage: String?
    ) {
        let path = activeWorktreePath(for: project)
        Task {
            let result = await ObsidianJourneyLogService.logSession(
                outcome: outcome,
                proposal: proposal,
                projectName: project.name,
                projectPath: path,
                overriddenBlocker: overrideBlocker,
                settings: ObsidianMCPSettingsStore.shared.snapshot
            )
            await MainActor.run {
                switch result {
                case let .success(notePath):
                    if let successMessage {
                        ToastState.shared.show("\(successMessage) → \(notePath)")
                    }
                case let .failure(error):
                    if let successMessage {
                        ToastState.shared.show("\(successMessage) (Obsidian log failed: \(error.localizedDescription))")
                    }
                }
            }
        }
    }

    private func performObsidianMCPTool(_ action: ObsidianMCPToolAction, query: String?) {
        switch action {
        case .sendCapture:
            sendToObsidian()
        case .openSettings:
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            SettingsFocusCoordinator.shared.request(.mcpTools)
        case .listInboxNotes:
            runObsidianMCPTool(action) { settings in
                ["folder": settings.inboxFolder]
            }
        case .searchNotes:
            let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else {
                ToastState.shared.show("Type a search query in the command palette first")
                return
            }
            runObsidianMCPTool(action) { _ in
                ["query": trimmed]
            }
        case .getAllTags:
            runObsidianMCPTool(action) { _ in [:] }
        case .getFolderStructure:
            runObsidianMCPTool(action) { _ in [:] }
        }
    }

    private func promptObsidianSearch() {
        let alert = NSAlert()
        alert.messageText = "Search Obsidian Notes"
        alert.informativeText = "Search titles, content, and tags in your vault."
        alert.addButton(withTitle: "Search")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        input.placeholderString = "Search query"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let trimmed = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ToastState.shared.show("Enter a search query")
            return
        }
        performObsidianMCPTool(.searchNotes, query: trimmed)
    }

    private func runObsidianMCPTool(
        _ action: ObsidianMCPToolAction,
        arguments: @escaping (ObsidianMCPSettings) -> [String: Any]
    ) {
        guard let toolName = action.toolName else { return }
        let settings = ObsidianMCPSettingsStore.shared.snapshot
        Task {
            let result = await ObsidianMCPService.runTool(
                toolName,
                arguments: arguments(settings),
                settings: settings
            )
            await MainActor.run {
                switch result {
                case let .success(response):
                    ToastState.shared.show(ObsidianMCPService.summaryMessage(for: action, response: response))
                case let .failure(error):
                    ToastState.shared.show(error.localizedDescription)
                }
            }
        }
    }

    private func performRemoteCommandPaletteAction(_ action: RemoteCommandPaletteAction) {
        guard let space = activeRemoteSpace else {
            ToastState.shared.show("Select a remote space first")
            return
        }
        switch action {
        case .openSession:
            RemoteSpaceLauncher.open(
                space,
                appState: appState,
                projectStore: projectStore,
                worktreeStore: worktreeStore
            )
        case .copySSHCommand:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(space.connectionCommand, forType: .string)
            ToastState.shared.show("Copied SSH command")
        case .systemOverview,
             .updateLinux,
             .reboot,
             .powerOff,
             .gpuStatus,
             .gpuMonitor:
            runRemoteCommandPaletteAction(action, in: space)
        }
    }

    private func runRemoteCommandPaletteAction(_ action: RemoteCommandPaletteAction, in space: RemoteSpace) {
        guard let command = action.command else { return }
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: action.tabTitle(for: space),
            command: RemoteCommandBuilder.command(command, for: space)
        ))
    }

    private func runLocalCommandPaletteAction(_ action: LocalCommandPaletteAction) {
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        guard ensureLocalCommandWorkspace(for: projectID) else {
            ToastState.shared.show("Open a workspace first")
            return
        }
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: action.tabTitle,
            command: action.command(ollamaModel: NaturalCommandSettings.shared.ollamaModel)
        ))
    }

    private func ensureLocalCommandWorkspace(for projectID: UUID) -> Bool {
        if appState.workspaceRoot(for: projectID) != nil,
           appState.focusedArea(for: projectID) != nil
        {
            return true
        }
        guard let project = projectStore.projects.first(where: { $0.id == projectID }) else { return false }
        worktreeStore.ensurePrimary(for: project)
        guard let worktree = worktreeStore.preferred(
            for: projectID,
            matching: appState.activeWorktreeID[projectID]
        )
        else { return false }
        appState.selectWorktree(projectID: projectID, worktree: worktree)
        return appState.workspaceRoot(for: projectID) != nil
            && appState.focusedArea(for: projectID) != nil
    }

    private func runSnippetFromPalette(_ snippetID: UUID) {
        SnippetsStore.shared.selectScope(activeSnippetScope)
        guard let snippet = SnippetsStore.shared.snippets.first(where: { $0.id == snippetID }) else { return }
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: commandPaletteSnippetTitle(snippet, remoteSpace: activeRemoteSpace),
            command: activeRemoteSpace.map { RemoteCommandBuilder.command(snippet.trimmedCommand, for: $0) } ?? snippet.trimmedCommand
        ))
    }

    private func commandPaletteSnippetTitle(_ snippet: Snippet, remoteSpace: RemoteSpace?) -> String {
        guard let remoteSpace else { return snippet.displayName }
        return "\(remoteSpace.displayName) · \(snippet.displayName)"
    }

    private func runNaturalCommandPlan(_ plan: NaturalCommandPlan) {
        guard plan.isRunnable else {
            ToastState.shared.show(plan.blockedReason ?? "Command blocked")
            return
        }
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        let command = activeRemoteSpace.map {
            RemoteCommandBuilder.command(plan.primaryCommand, for: $0)
        } ?? plan.primaryCommand
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: plan.title,
            command: command
        ))
        showCommandPalette = false
    }

    private func saveNaturalCommandPlan(_ plan: NaturalCommandPlan) {
        guard !plan.primaryCommand.isEmpty else { return }
        SnippetsStore.shared.selectScope(activeSnippetScope)
        let snippet = Snippet(
            name: plan.title,
            description: plan.summary,
            command: plan.primaryCommand,
            tags: ["generated", plan.targetKind.rawValue, plan.riskLevel.rawValue]
        )
        if SnippetsStore.shared.add(snippet) != nil {
            ToastState.shared.show("Saved snippet")
        }
    }

    private func toggleSnippetsPanel() {
        let next = SidePanelPolicy.toggling(.snippets, in: sidePanelVisibility)
        applySidePanelVisibility(next)
        notifyIfPanelSuppressed(
            requestedVisible: snippetsPanelVisible,
            suppressed: narrowLayoutAdjustments.hideSnippets,
            panelName: "Snippets"
        )
    }

    private func toggleNotesPanel() {
        if richInputPanelVisible, richInputMode == .notes {
            closeRichInputPanel()
            return
        }
        guard activeProject != nil else {
            ToastState.shared.show("Select a project first")
            return
        }
        notesPanelVisible = true
        UserDefaults.standard.set(true, forKey: "muxy.notesPanelVisible")
        openRichInputPanel(mode: .notes)
    }

    private func toggleTodoPanel() {
        toggleNotesPanel()
    }

    private func toggleRichInputPreview() {
        if showRichInputPreview {
            showRichInputPreview = false
            return
        }
        guard activeProject != nil else {
            ToastState.shared.show("Select a project first")
            return
        }
        projectInspectorStore.selectProject(appState.activeProjectID)
        showRichInputPreview = true
    }

    private func sendToObsidian() {
        Task {
            await performSendToObsidian()
        }
    }

    private func performSendToObsidian() async {
        guard let content = SendToObsidianContentCapture.capture(
            terminalPaneID: activeTerminalPane?.id,
            richInputText: activeRichInputState?.text,
            richInputVisible: richInputPanelVisible
        )
        else {
            ToastState.shared.show("Nothing to send to Obsidian")
            return
        }

        let result = await ObsidianSendService.send(
            content: content,
            projectName: activeProject?.name
        )
        switch result {
        case let .success(path):
            ToastState.shared.show("Saved to Obsidian: \(path)")
        case let .failure(error):
            ToastState.shared.show(error.localizedDescription)
        }
    }

    private func toggleRichInputPreviewTask(lineIndex: Int) {
        let markdown = projectInspectorStore.workspaceMarkdown
        guard let updated = ProjectWorkspaceMarkdown.toggleTaskLine(at: lineIndex, in: markdown) else { return }
        projectInspectorStore.updateWorkspace(updated)
        NotificationCenter.default.post(name: .richInputPreviewDidMutateWorkspace, object: nil)
    }

    private func copyRichInputPreviewText(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            ToastState.shared.show("Nothing to copy")
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        ToastState.shared.show("Copied")
    }

    private func toggleAIAssistantPanel() {
        let next = SidePanelPolicy.toggling(.ai, in: sidePanelVisibility)
        applySidePanelVisibility(next)
        notifyIfPanelSuppressed(
            requestedVisible: aiAssistantPanelVisible,
            suppressed: narrowLayoutAdjustments.hideAI,
            panelName: "Assistant"
        )
    }

    private var sidePanelVisibility: SidePanelVisibility {
        SidePanelVisibility(
            snippets: snippetsPanelVisible,
            ai: aiAssistantPanelVisible,
            notes: notesPanelVisible,
            todo: todoPanelVisible
        )
    }

    private func applySidePanelVisibility(_ visibility: SidePanelVisibility) {
        snippetsPanelVisible = visibility.snippets
        aiAssistantPanelVisible = visibility.ai
        notesPanelVisible = visibility.notes
        todoPanelVisible = visibility.todo
        UserDefaults.standard.set(visibility.snippets, forKey: "muxy.snippetsPanelVisible")
        UserDefaults.standard.set(visibility.notes, forKey: "muxy.notesPanelVisible")
        UserDefaults.standard.set(visibility.todo, forKey: "muxy.todoPanelVisible")
    }

    private func notifyIfPanelSuppressed(requestedVisible: Bool, suppressed: Bool, panelName: String) {
        guard requestedVisible, suppressed else { return }
        ToastState.shared.show("\(panelName) hidden — widen the window")
    }

    private func shortcutUnavailableReason(for action: ShortcutAction) -> String {
        switch action {
        case .newTab,
             .closeTab,
             .pinUnpinTab,
             .splitRight,
             .splitDown,
             .closePane,
             .focusPaneLeft,
             .focusPaneRight,
             .focusPaneUp,
             .focusPaneDown,
             .cycleNextTabAcrossPanes,
             .cyclePreviousTabAcrossPanes,
             .nextTab,
             .previousTab,
             .openVCSTab,
             .toggleMaximizePane,
             .selectTab1,
             .selectTab2,
             .selectTab3,
             .selectTab4,
             .selectTab5,
             .selectTab6,
             .selectTab7,
             .selectTab8,
             .selectTab9:
            guard appState.activeProjectID != nil else { return "Select a project first" }
            if action == .newTab,
               let projectID = appState.activeProjectID,
               appState.workspaceRoot(for: projectID) == nil
            {
                return "Select a worktree first"
            }
            if action == .closeTab {
                return "No closable tab in the focused pane"
            }
            if action == .closePane {
                return "No focused pane to close"
            }
            if action == .toggleMaximizePane {
                return "No focused pane to maximize"
            }
            return "Unavailable for the current workspace"
        case .openLazygit,
             .openYazi:
            guard appState.activeProjectID != nil else { return "Select a project first" }
            return "Open a project worktree first"
        case .navigateBack:
            return "No back history"
        case .navigateForward:
            return "No forward history"
        case .toggleAIUsage:
            return "AI usage tracking is disabled in Settings"
        case .toggleSnippetsScope:
            return "Select a project first"
        case .newProject:
            return "Use Open Project instead"
        case .submitRichInput,
             .submitRichInputWithoutReturn,
             .toggleVoiceRecording:
            return "Unavailable here"
        default:
            return "Unavailable right now"
        }
    }

    private func showTodoPanel() {
        guard !richInputPanelVisible || richInputMode != .notes else { return }
        toggleNotesPanel()
    }

    private func handleExplainSelection(notification: Notification) {
        guard let selection = notification.userInfo?["selection"] as? String,
              let filePath = notification.userInfo?["filePath"] as? String,
              let projectID = appState.activeProjectID
        else { return }
        var next = sidePanelVisibility
        if !next.ai {
            next = SidePanelPolicy.toggling(.ai, in: next)
        }
        applySidePanelVisibility(next)
        NotificationCenter.default.post(name: .focusAIAssistantInput, object: nil)
        let prompt = "Explain this code from \(URL(fileURLWithPath: filePath).lastPathComponent):\n\n```\n\(selection)\n```"
        AIAssistantChatService.shared.send(context: InspectorChatContext(
            prompt: prompt,
            projectID: projectID,
            projectPath: activeProject.map { activeWorktreePath(for: $0) },
            activeFile: filePath,
            worktreeID: activeWorktreeKey?.worktreeID,
            worktreePath: activeProject.map { activeWorktreePath(for: $0) }
        ))
    }

    private func handleApplyAIAssistantCode(notification: Notification) {
        guard let code = notification.userInfo?["code"] as? String,
              let filePath = notification.userInfo?["filePath"] as? String,
              let projectID = appState.activeProjectID
        else { return }
        appState.applyAIAssistantCode(code, filePath: filePath, projectID: projectID)
    }

    private func syncProjectInspectorStore() {
        projectInspectorStore.selectProject(appState.activeProjectID)
    }

    private var openerItems: [OpenerItem] {
        var items: [OpenerItem] = []

        for project in projectStore.projects {
            items.append(.project(.init(
                projectID: project.id,
                projectName: project.name
            )))
        }

        for project in projectStore.projects {
            for worktree in worktreeStore.list(for: project.id) {
                items.append(.worktree(.init(
                    projectID: project.id,
                    projectName: project.name,
                    worktreeID: worktree.id,
                    worktreeName: worktree.isPrimary && worktree.name.isEmpty ? "main" : worktree.name,
                    branch: worktree.branch,
                    isPrimary: worktree.isPrimary
                )))
            }
        }

        if let active = activeProject {
            for descriptor in appState.availableLayouts(for: active.id) {
                items.append(.layout(.init(
                    projectID: active.id,
                    projectName: active.name,
                    layoutName: descriptor.name
                )))
            }

            let worktrees = worktreeStore.list(for: active.id)
            for branch in BranchCache.shared.branches(for: active.path) {
                let matching = worktrees.first { $0.branch == branch }
                items.append(.branch(.init(
                    projectID: active.id,
                    projectName: active.name,
                    branch: branch,
                    matchingWorktreeID: matching?.id
                )))
            }

            for area in appState.allAreas(for: active.id) {
                for tab in area.tabs {
                    items.append(.openTab(.init(
                        projectID: active.id,
                        projectName: active.name,
                        areaID: area.id,
                        tabID: tab.id,
                        title: tab.title,
                        kind: tab.kind.rawValue
                    )))
                }
            }
        }

        return items
    }

    private var openerRecentItems: [OpenerItem] {
        let allByID = Dictionary(uniqueKeysWithValues: openerItems.map { ($0.id, $0) })
        return OpenerPreferences.recents.compactMap { allByID[$0.key] }
    }

    private func handleOpenerSelection(_ item: OpenerItem) {
        OpenerPreferences.remember(.init(key: item.id, category: item.category))
        switch item {
        case let .project(project):
            guard let target = projectStore.projects.first(where: { $0.id == project.projectID }) else { return }
            let worktree = worktreeStore.preferred(for: target.id, matching: appState.activeWorktreeID[target.id])
            if let worktree {
                appState.selectProject(target, worktree: worktree)
            }
        case let .worktree(wt):
            guard let target = projectStore.projects.first(where: { $0.id == wt.projectID }),
                  let worktree = worktreeStore.list(for: wt.projectID).first(where: { $0.id == wt.worktreeID })
            else { return }
            if appState.activeProjectID == wt.projectID {
                appState.selectWorktree(projectID: wt.projectID, worktree: worktree)
            } else {
                appState.selectProject(target, worktree: worktree)
            }
        case let .layout(layout):
            appState.requestApplyLayout(projectID: layout.projectID, layoutName: layout.layoutName)
        case let .branch(br):
            if let worktreeID = br.matchingWorktreeID,
               let worktree = worktreeStore.list(for: br.projectID).first(where: { $0.id == worktreeID }),
               let project = projectStore.projects.first(where: { $0.id == br.projectID })
            {
                if appState.activeProjectID == br.projectID {
                    appState.selectWorktree(projectID: br.projectID, worktree: worktree)
                } else {
                    appState.selectProject(project, worktree: worktree)
                }
            } else {
                ToastState.shared.show("No worktree for '\(br.branch)'")
            }
        case let .openTab(tab):
            appState.dispatch(.selectTab(projectID: tab.projectID, areaID: tab.areaID, tabID: tab.tabID))
        }
    }

    private var projectsWithWorkspaces: [Project] {
        projectStore.projects.filter { appState.workspaceRoot(for: $0.id) != nil }
    }

    @ViewBuilder
    private var floatingRichInputOverlay: some View {
        if isRichInputVisible(floating: true, at: .right) {
            richInputPanelContent(at: .right)
                .background(MuxyTheme.bg)
                .transition(.move(edge: .trailing))
        }
    }

    @ViewBuilder
    private var bottomDockedRichInputPanel: some View {
        if isRichInputVisible(floating: false, at: .bottom) {
            richInputPanelContent(at: .bottom)
        }
    }

    @ViewBuilder
    private var floatingBottomRichInputOverlay: some View {
        if isRichInputVisible(floating: true, at: .bottom) {
            richInputPanelContent(at: .bottom)
                .background(MuxyTheme.bg)
                .transition(.move(edge: .bottom))
        }
    }

    private func isRichInputVisible(floating: Bool, at position: RichInputPanelPosition) -> Bool {
        richInputPanelVisible
            && richInputFloating == floating
            && richInputPosition == position
            && activeRichInputState != nil
            && activeWorktreeKey != nil
    }

    @ViewBuilder
    private func richInputPanelContent(at position: RichInputPanelPosition) -> some View {
        if let richInputState = activeRichInputState, let worktreeKey = activeWorktreeKey {
            let panel = RichInputSidePanel(
                state: richInputState,
                worktreeKey: worktreeKey,
                mode: richInputMode,
                projectID: appState.activeProjectID,
                onDismiss: { closeRichInputPanel() },
                onSubmit: { appendReturn in submitRichInput(richInputState, appendReturn: appendReturn) }
            )
            switch position {
            case .right:
                HStack(spacing: 0) {
                    sidePanelResizeHandle { delta in
                        let next = richInputPanelWidth - Double(delta)
                        richInputPanelWidth = max(
                            Double(RichInputPanelLayout.minWidth),
                            min(Double(RichInputPanelLayout.maxWidth), next)
                        )
                    }
                    panel.frame(width: CGFloat(richInputPanelWidth))
                }
            case .bottom:
                VStack(spacing: 0) {
                    bottomPanelResizeHandle { delta in
                        let next = richInputPanelHeight - Double(delta)
                        richInputPanelHeight = max(
                            Double(RichInputPanelLayout.minHeight),
                            min(Double(RichInputPanelLayout.maxHeight), next)
                        )
                    }
                    panel.frame(height: CGFloat(richInputPanelHeight))
                }
            }
        }
    }

    @ViewBuilder
    private var rightSidePanel: some View {
        if isRichInputVisible(floating: false, at: .right) {
            richInputPanelContent(at: .right)
        } else if vcsPanelVisible, VCSDisplayMode.current == .attached, let state = activeVCSState {
            HStack(spacing: 0) {
                sidePanelResizeHandle { delta in
                    vcsPanelWidth = max(
                        AttachedVCSLayout.minWidth,
                        min(AttachedVCSLayout.maxWidth, vcsPanelWidth - delta)
                    )
                }
                VCSTabView(state: state, focused: false, onFocus: {})
                    .frame(width: vcsPanelWidth)
            }
        } else if fileTreePanelVisible, let treeState = activeFileTreeState {
            HStack(spacing: 0) {
                sidePanelResizeHandle { delta in
                    let next = fileTreePanelWidth - Double(delta)
                    fileTreePanelWidth = max(
                        Double(FileTreeLayout.minWidth),
                        min(Double(FileTreeLayout.maxWidth), next)
                    )
                }
                FileTreeView(
                    state: treeState,
                    onOpenFile: { filePath in
                        guard let projectID = appState.activeProjectID else { return }
                        appState.openFile(filePath, projectID: projectID, preserveFocus: true)
                    },
                    onOpenTerminal: { directory in
                        guard let projectID = appState.activeProjectID else { return }
                        appState.dispatch(.createTabInDirectory(
                            projectID: projectID,
                            areaID: nil,
                            directory: directory
                        ))
                    },
                    onFileMoved: { oldPath, newPath in
                        appState.handleFileMoved(from: oldPath, to: newPath)
                    }
                )
                .id(activeFileTreeIdentity)
                .frame(width: CGFloat(fileTreePanelWidth))
            }
        }
    }

    private func sidePanelResizeHandle(onDrag: @escaping (CGFloat) -> Void) -> some View {
        ResizeHandle(axis: .horizontal) { v in
            onDrag(v.translation.width)
        }
        .accessibilityHidden(true)
    }

    private func bottomPanelResizeHandle(onDrag: @escaping (CGFloat) -> Void) -> some View {
        ResizeHandle(axis: .vertical) { v in
            onDrag(v.translation.height)
        }
        .accessibilityHidden(true)
    }

    private var activeFileTreeState: FileTreeState? {
        guard let project = activeProject,
              let key = appState.activeWorktreeKey(for: project.id)
        else { return nil }
        return fileTreeStates[key]
    }

    private var activeFileTreeIdentity: WorktreeKey? {
        guard let project = activeProject else { return nil }
        return appState.activeWorktreeKey(for: project.id)
    }

    private func ensureFileTreeState(for project: Project) {
        guard let key = appState.activeWorktreeKey(for: project.id) else { return }
        let path = resolvedFileTreeRoot(for: project, key: key)
        if let existing = fileTreeStates[key] {
            existing.setRootPath(path)
            return
        }
        fileTreeStates[key] = FileTreeState(rootPath: path)
    }

    private var fileTreeSource: FileTreeSourcePreference {
        FileTreeSourcePreference(rawValue: fileTreeSourceRaw) ?? .projectBase
    }

    private func resolvedFileTreeRoot(for project: Project, key: WorktreeKey) -> String {
        let base = activeWorktreePath(for: project)
        guard fileTreeSource == .activeTerminal else { return base }
        if let cwd = appState.activeTab(for: project.id)?.content.pane?.currentWorkingDirectory {
            fileTreeLastTerminalPaths[key] = cwd
            return cwd
        }
        return fileTreeLastTerminalPaths[key] ?? base
    }

    private func refreshFileTreeRootForActiveTerminal() {
        guard fileTreeSource == .activeTerminal,
              fileTreePanelVisible,
              let project = activeProject
        else { return }
        ensureFileTreeState(for: project)
    }

    private var activeEditorState: EditorTabState? {
        guard let project = activeProject else { return nil }
        return appState.activeTab(for: project.id)?.content.editorState
    }

    private var anyOpenEditorFilePath: String? {
        guard let project = activeProject,
              appState.activeWorktreeKey(for: project.id) != nil,
              let root = appState.workspaceRoot(for: project.id)
        else { return nil }
        for area in root.allAreas() {
            for tab in area.tabs {
                if let filePath = tab.content.editorState?.filePath {
                    return filePath
                }
            }
        }
        return nil
    }

    private var activeEditorFilePath: String? {
        activeEditorState?.filePath
    }

    private func activeEditorCursor() -> (line: Int?, column: Int?) {
        guard let state = activeEditorState else { return (nil, nil) }
        return (state.cursorLine, state.cursorColumn)
    }

    private func syncFileTreeSelection(filePath: String?) {
        guard fileTreePanelVisible,
              let project = activeProject,
              let key = appState.activeWorktreeKey(for: project.id),
              let state = fileTreeStates[key]
        else { return }
        if let filePath {
            state.revealFile(at: filePath)
        } else {
            state.clearSelection()
        }
    }

    private func pruneFileTreeStates() {
        let validKeys = validVCSKeys()
        fileTreeStates = fileTreeStates.filter { validKeys.contains($0.key) }
        fileTreeLastTerminalPaths = fileTreeLastTerminalPaths.filter { validKeys.contains($0.key) }
        richInputStates = richInputStates.filter { validKeys.contains($0.key) }
    }

    private func toggleAttachedVCSPanel() {
        guard VCSDisplayMode.current == .attached,
              activeProject != nil
        else {
            vcsPanelVisible = false
            return
        }

        let isShowing = !vcsPanelVisible
        vcsPanelVisible = isShowing
        if isShowing {
            fileTreePanelVisible = false
            panelToRestoreAfterRichInput = nil
            closeRichInputPanel()
        }
    }

    private func toggleFileTreePanel() {
        guard let project = activeProject else {
            if fileTreePanelVisible {
                fileTreePanelVisible = false
                NotificationCenter.default.post(name: .refocusActiveTerminal, object: nil)
            }
            return
        }

        ensureFileTreeState(for: project)
        let isShowing = !fileTreePanelVisible
        fileTreePanelVisible = isShowing
        if isShowing {
            vcsPanelVisible = false
            panelToRestoreAfterRichInput = nil
            closeRichInputPanel()
        } else {
            NotificationCenter.default.post(name: .refocusActiveTerminal, object: nil)
        }
    }

    private var activeRichInputState: RichInputState? {
        guard let project = activeProject,
              let key = appState.activeWorktreeKey(for: project.id)
        else { return nil }
        if let existing = richInputStates[key] { return existing }
        let new = RichInputState()
        if let draft = RichInputDraftStore.shared.draft(for: key) {
            new.apply(draft)
        }
        richInputStates[key] = new
        return new
    }

    private var activeRichInputPaneID: UUID? {
        activeTerminalPane?.id
    }

    private var activeTerminalPane: TerminalPaneState? {
        guard let project = activeProject else { return nil }
        return appState.activeTab(for: project.id)?.content.pane
    }

    private func toggleRichInputPanel() {
        guard let richInputState = activeRichInputState else { return }
        guard richInputPanelVisible else {
            richInputMode = .send
            prepareRichInputSidePanelOpening()
            richInputPanelVisible = true
            richInputState.focusVersion += 1
            return
        }
        if richInputMode == .send, NSApp.keyWindow?.firstResponder is MarkdownEditingTextView {
            closeRichInputPanel()
        } else {
            richInputMode = .send
            richInputState.focusVersion += 1
        }
    }

    private func openRichInputPanel(mode: RichInputPanelMode) {
        guard let richInputState = activeRichInputState else { return }
        richInputMode = mode
        prepareRichInputSidePanelOpening()
        richInputPanelVisible = true
        richInputState.focusVersion += 1
    }

    private func prepareRichInputSidePanelOpening() {
        if richInputReplacesRightSidePanel {
            if vcsPanelVisible {
                panelToRestoreAfterRichInput = .vcs
            } else if fileTreePanelVisible {
                panelToRestoreAfterRichInput = .fileTree
            } else {
                panelToRestoreAfterRichInput = nil
            }
            vcsPanelVisible = false
            fileTreePanelVisible = false
        } else {
            panelToRestoreAfterRichInput = nil
        }
    }

    private var richInputReplacesRightSidePanel: Bool {
        !richInputFloating && richInputPosition == .right
    }

    private func closeRichInputPanel() {
        richInputPanelVisible = false
        notesPanelVisible = false
        todoPanelVisible = false
        UserDefaults.standard.set(false, forKey: "muxy.notesPanelVisible")
        UserDefaults.standard.set(false, forKey: "muxy.todoPanelVisible")
        richInputMode = .send
        let panelToRestore = panelToRestoreAfterRichInput
        panelToRestoreAfterRichInput = nil
        switch panelToRestore {
        case .vcs:
            if VCSDisplayMode.current == .attached, activeProject != nil {
                vcsPanelVisible = true
                return
            }
        case .fileTree:
            if let project = activeProject {
                ensureFileTreeState(for: project)
                fileTreePanelVisible = true
                return
            }
        case .none:
            break
        }
        guard let paneID = activeRichInputPaneID,
              let view = TerminalViewRegistry.shared.existingView(for: paneID)
        else { return }
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
    }

    private func submitRichInput(_ richInput: RichInputState, appendReturn: Bool) {
        let paneIDs = richInputBroadcast ? visibleTerminalPaneIDs() : [activeRichInputPaneID].compactMap(\.self)
        guard !paneIDs.isEmpty else { return }
        RichInputSubmitter.submit(richInput: richInput, paneIDs: paneIDs, appendReturn: appendReturn)
    }

    private func visibleTerminalPaneIDs() -> [UUID] {
        guard let project = activeProject,
              let root = appState.workspaceRoot(for: project.id)
        else { return [] }
        return root.allAreas().compactMap { $0.activeTab?.content.pane?.id }
    }

    private var activeVCSState: VCSTabState? {
        guard let project = activeProject,
              appState.activeWorktreeKey(for: project.id) != nil
        else { return nil }
        return VCSStateStore.shared.state(for: activeWorktreePath(for: project))
    }

    private func activeWorktreePath(for project: Project) -> String {
        guard let key = appState.activeWorktreeKey(for: project.id) else { return project.path }
        return worktreeStore
            .worktree(projectID: project.id, worktreeID: key.worktreeID)?
            .path ?? project.path
    }

    private func openVCS(for project: Project, preferredAreaID: UUID? = nil) {
        VCSDisplayMode.current.route(
            tab: {
                let areaID = preferredAreaID
                    ?? appState.focusedAreaID(for: project.id)
                    ?? appState.workspaceRoot(for: project.id)?.allAreas().first?.id
                guard let areaID else { return }
                appState.dispatch(.createVCSTab(projectID: project.id, areaID: areaID))
            },
            window: { openWindow(id: "vcs") },
            attached: {
                toggleAttachedVCSPanel()
            }
        )
    }

    private func validVCSKeys() -> Set<WorktreeKey> {
        var keys: Set<WorktreeKey> = []
        for project in projectStore.projects {
            for worktree in worktreeStore.list(for: project.id) {
                keys.insert(WorktreeKey(projectID: project.id, worktreeID: worktree.id))
            }
        }
        return keys
    }

    private var vcsPruneSignature: [String] {
        var result: [String] = []
        for project in projectStore.projects {
            result.append(project.id.uuidString)
            for worktree in worktreeStore.list(for: project.id) {
                result.append(worktree.id.uuidString)
            }
        }
        return result
    }

    private var vcsEnsureSignature: String {
        let projectID = appState.activeProjectID?.uuidString ?? ""
        let worktreeID = appState.activeProjectID.flatMap { appState.activeWorktreeID[$0] }?.uuidString ?? ""
        return "\(projectID):\(worktreeID)"
    }

    private func presentCloseConfirmation(_ kind: CloseConfirmationKind) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              window.attachedSheet == nil
        else { return }

        let alert = NSAlert()
        alert.messageText = kind.title
        alert.informativeText = kind.message
        alert.alertStyle = .warning
        alert.icon = NSApp.applicationIconImage

        switch kind {
        case .unsavedEditor:
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Don't Save")
            alert.buttons[0].keyEquivalent = "\r"
            alert.buttons[1].keyEquivalent = "\u{1b}"
            alert.buttons[2].keyEquivalent = "d"
            alert.buttons[2].keyEquivalentModifierMask = [.command]
        case .lastTab,
             .runningProcess:
            alert.addButton(withTitle: "Close")
            alert.addButton(withTitle: "Cancel")
            alert.buttons[0].keyEquivalent = "\r"
            alert.buttons[1].keyEquivalent = "\u{1b}"
        }

        if kind == .runningProcess {
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = "Don't ask again"
        }

        alert.beginSheetModal(for: window) { response in
            switch kind {
            case .lastTab:
                if response == .alertFirstButtonReturn {
                    appState.confirmCloseLastTab()
                } else {
                    appState.cancelCloseLastTab()
                }
            case .unsavedEditor:
                switch response {
                case .alertFirstButtonReturn:
                    appState.saveAndCloseUnsavedEditorTab()
                case .alertThirdButtonReturn:
                    appState.confirmCloseUnsavedEditorTab()
                default:
                    appState.cancelCloseUnsavedEditorTab()
                }
            case .runningProcess:
                if response == .alertFirstButtonReturn {
                    if alert.suppressionButton?.state == .on {
                        TabCloseConfirmationPreferences.confirmRunningProcess = false
                    }
                    appState.confirmCloseRunningTab()
                } else {
                    appState.cancelCloseRunningTab()
                }
            }
        }
    }

    private func presentSaveErrorAlert(message: String) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              window.attachedSheet == nil
        else {
            appState.pendingSaveErrorMessage = nil
            return
        }

        let alert = NSAlert()
        alert.messageText = "Could Not Save File"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "OK")
        alert.buttons[0].keyEquivalent = "\r"

        alert.beginSheetModal(for: window) { _ in
            appState.pendingSaveErrorMessage = nil
        }
    }

    private func presentLayoutApplyConfirmation(pending: AppState.PendingLayoutApply) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow,
              window.attachedSheet == nil
        else {
            appState.cancelApplyLayout()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Apply Layout '\(pending.layoutName)'?"
        alert.informativeText = "All terminals and tabs in this worktree will be closed and replaced with the layout."
        alert.alertStyle = .warning
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "Apply")
        alert.addButton(withTitle: "Cancel")
        alert.buttons[0].keyEquivalent = "\r"
        alert.buttons[1].keyEquivalent = "\u{1b}"

        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                appState.confirmApplyLayout()
            } else {
                appState.cancelApplyLayout()
            }
        }
    }
}

private struct WindowTitleUpdater: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.title = title
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let window = nsView.window, window.title != title else { return }
        window.title = title
    }
}

private struct FileTreeSelectionSync: ViewModifier {
    let filePath: String?
    let panelVisible: Bool
    let sync: (String?) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: filePath) { _, newValue in
                sync(newValue)
            }
            .onChange(of: panelVisible) { _, visible in
                guard visible else { return }
                sync(filePath)
            }
    }
}

private struct FileTreeSourceObserver: ViewModifier {
    let activeTerminalCWD: String?
    let activeTerminalID: UUID?
    let sourceRaw: String
    let onTerminalChange: () -> Void
    let onSourceChange: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: activeTerminalCWD) { _, _ in onTerminalChange() }
            .onChange(of: activeTerminalID) { _, _ in onTerminalChange() }
            .onChange(of: sourceRaw) { _, _ in onSourceChange() }
    }
}

private struct RemoteSpaceThemeSync: ViewModifier {
    let projectID: UUID?
    let activeSpace: RemoteSpace?

    func body(content: Content) -> some View {
        content
            .onChange(of: projectID) {
                apply()
            }
            .onAppear {
                apply()
            }
    }

    private func apply() {
        guard let activeSpace else { return }
        RemoteSpaceLauncher.applyTheme(for: activeSpace)
    }
}

private struct NavigationArrowButton: View {
    let symbol: String
    let isEnabled: Bool
    let label: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.fontBody, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: UIMetrics.scaled(22), height: UIMetrics.scaled(22))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { hovered = $0 }
        .help(label)
        .accessibilityLabel(label)
    }

    private var foregroundColor: Color {
        guard isEnabled else { return MuxyTheme.fgMuted.opacity(0.35) }
        return hovered ? MuxyTheme.fg : MuxyTheme.fgMuted
    }
}

private struct UtilityOverlay<Content: View>: View {
    let onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            content()
                .background(MuxyTheme.bg, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(MuxyTheme.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 24, x: 0, y: 18)
        }
        .onExitCommand(perform: onDismiss)
    }
}

private struct MainWindowShortcutInterceptor: NSViewRepresentable {
    let onShortcut: (ShortcutAction) -> Bool
    let onCommandShortcut: (CommandShortcut) -> Bool
    let onMouseBack: () -> Void
    let onMouseForward: () -> Void

    func makeNSView(context: Context) -> ShortcutInterceptingView {
        let view = ShortcutInterceptingView()
        view.onShortcut = onShortcut
        view.onCommandShortcut = onCommandShortcut
        view.onMouseBack = onMouseBack
        view.onMouseForward = onMouseForward
        return view
    }

    func updateNSView(_ nsView: ShortcutInterceptingView, context: Context) {
        nsView.onShortcut = onShortcut
        nsView.onCommandShortcut = onCommandShortcut
        nsView.onMouseBack = onMouseBack
        nsView.onMouseForward = onMouseForward
    }
}

private final class ShortcutInterceptingView: NSView {
    var onShortcut: ((ShortcutAction) -> Bool)?
    var onCommandShortcut: ((CommandShortcut) -> Bool)?
    var onMouseBack: (() -> Void)?
    var onMouseForward: (() -> Void)?
    private var mouseMonitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            removeMouseMonitor()
        } else {
            installMouseMonitorIfNeeded()
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              ShortcutContext.isMainWindow(window)
        else { return super.performKeyEquivalent(with: event) }

        let scopes = ShortcutContext.activeScopes(for: window)
        let layerWasActive = CommandShortcutStore.shared.isLayerActive
        if let shortcut = CommandShortcutStore.shared.shortcut(for: event, scopes: scopes) {
            CommandShortcutStore.shared.deactivateLayer()
            _ = onCommandShortcut?(shortcut)
            return true
        }

        if layerWasActive {
            CommandShortcutStore.shared.deactivateLayer()
            return true
        }

        if CommandShortcutStore.shared.matchesPrefix(event: event, scopes: scopes) {
            CommandShortcutStore.shared.activateLayer()
            return true
        }

        if let action = KeyBindingStore.shared.action(for: event, scopes: scopes) {
            if onShortcut?(action) == true {
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }

    private func installMouseMonitorIfNeeded() {
        guard mouseMonitor == nil else { return }
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.otherMouseDown, .swipe]) { [weak self] event in
            guard let self,
                  let window = self.window,
                  window.isKeyWindow,
                  ShortcutContext.isMainWindow(window)
            else { return event }
            return self.handleNavigationEvent(event)
        }
    }

    private func handleNavigationEvent(_ event: NSEvent) -> NSEvent? {
        switch event.type {
        case .otherMouseDown:
            switch event.buttonNumber {
            case 3:
                onMouseBack?()
                return nil
            case 4:
                onMouseForward?()
                return nil
            default:
                return event
            }
        case .swipe:
            if event.deltaX > 0 {
                onMouseBack?()
                return nil
            }
            if event.deltaX < 0 {
                onMouseForward?()
                return nil
            }
            return event
        default:
            return event
        }
    }

    private func removeMouseMonitor() {
        guard let mouseMonitor else { return }
        NSEvent.removeMonitor(mouseMonitor)
        self.mouseMonitor = nil
    }
}

private struct SentryConsentPrompter: ViewModifier {
    @State private var hasPrompted = false

    func body(content: Content) -> some View {
        content.task {
            guard !hasPrompted, SentryService.shared.needsPrompt else { return }
            hasPrompted = true
            await presentWhenWindowReady()
        }
    }

    @MainActor
    private func presentWhenWindowReady() async {
        if let window = readyWindow() {
            present(on: window)
            return
        }
        await waitForKeyWindow()
        if let window = readyWindow() {
            present(on: window)
        }
    }

    @MainActor
    private func waitForKeyWindow() async {
        let center = NotificationCenter.default
        let holder = ObserverHolder()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            holder.token = center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { _ in
                MainActor.assumeIsolated {
                    guard NSApp.keyWindow ?? NSApp.mainWindow != nil else { return }
                    if let token = holder.token {
                        center.removeObserver(token)
                        holder.token = nil
                        continuation.resume()
                    }
                }
            }
        }
    }

    @MainActor
    private func readyWindow() -> NSWindow? {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow else { return nil }
        return window.attachedSheet == nil ? window : nil
    }

    @MainActor
    private func present(on window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Help improve \(AppIdentity.displayName)?"
        alert.informativeText = """
        \(AppIdentity.displayName) can send anonymous crash and error reports so we can fix bugs faster. \
        No personal data, no project contents, no file paths are sent — only crash \
        details and an anonymous installation ID.

        You can change this anytime in Settings → General → Diagnostics.
        """
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don't Allow")
        alert.buttons[0].keyEquivalent = "\r"
        alert.buttons[1].keyEquivalent = "\u{1b}"

        alert.beginSheetModal(for: window) { response in
            let consent: SentryConsent = response == .alertFirstButtonReturn ? .allowed : .denied
            SentryService.shared.setConsent(consent)
        }
    }
}

@MainActor
private final class ObserverHolder {
    var token: NSObjectProtocol?
}

private struct OverlayExitTracker: ViewModifier {
    let showQuickOpen: Bool
    let showFindInFiles: Bool
    let showWorktreeSwitcher: Bool
    let showProjectPicker: Bool
    let onAnimatingOut: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: showQuickOpen) { _, visible in trackExit(visible) }
            .onChange(of: showFindInFiles) { _, visible in trackExit(visible) }
            .onChange(of: showWorktreeSwitcher) { _, visible in trackExit(visible) }
            .onChange(of: showProjectPicker) { _, visible in trackExit(visible) }
    }

    private func trackExit(_ visible: Bool) {
        guard !visible else { return }
        onAnimatingOut(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onAnimatingOut(false)
        }
    }
}
