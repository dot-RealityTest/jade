import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RichInputSidePanel: View {
    @Bindable var state: RichInputState
    let worktreeKey: WorktreeKey
    let mode: RichInputPanelMode
    let projectID: UUID?
    let onDismiss: () -> Void
    let onSubmit: (_ appendReturn: Bool) -> Void

    @State private var editorSettings = EditorSettings.shared
    @State private var inspectorStore = ProjectInspectorStore.shared
    @State private var workspaceText = ""
    @State private var slashContext: MarkdownSlashCommandContext?
    @State private var slashSelectedIndex = 0
    @State private var slashApplyRequest: MarkdownSlashCommandApplyRequest?
    @AppStorage(RichInputPreferences.fontSizeKey) private var fontSize: Double = RichInputPreferences.defaultFontSize
    @AppStorage(RichInputPreferences.positionKey) private var position: RichInputPanelPosition = RichInputPreferences
        .defaultPosition
    @AppStorage(RichInputPreferences.floatingKey) private var floating: Bool = RichInputPreferences.defaultFloating
    @AppStorage(RichInputPreferences.broadcastKey) private var broadcast: Bool = RichInputPreferences.defaultBroadcast

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(MuxyTheme.border).frame(height: 1)
            editorStack
            if mode == .send, !state.fileAttachments.isEmpty {
                Rectangle().fill(MuxyTheme.border).frame(height: 1)
                AttachmentChipsView(
                    attachments: state.fileAttachments,
                    onRemove: { url in
                        state.fileAttachments.removeAll { $0 == url }
                    }
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(MuxyTheme.bg)
            }
        }
        .background(MuxyTheme.bg)
        .onDrop(of: [UTType.fileURL, UTType.image], isTargeted: nil) { providers in
            guard mode == .send else { return false }
            return handleDrop(providers: providers)
        }
        .onAppear {
            if mode == .notes {
                syncWorkspaceFromStore()
            }
        }
        .onChange(of: projectID) { _, _ in
            if mode == .notes {
                syncWorkspaceFromStore()
            }
        }
        .onChange(of: state.text) {
            guard mode == .send else { return }
            persistDraft()
        }
        .onChange(of: state.fileAttachments) {
            guard mode == .send else { return }
            persistDraft()
        }
        .onChange(of: state.imageAttachments) {
            guard mode == .send else { return }
            persistDraft()
        }
        .onChange(of: workspaceText) {
            guard mode == .notes else { return }
            persistWorkspace()
        }
        .onReceive(NotificationCenter.default.publisher(for: .richInputPreviewDidMutateWorkspace)) { _ in
            guard mode == .notes else { return }
            syncWorkspaceFromStore()
        }
    }

    private var editorStack: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if mode == .send {
                    MarkdownTextEditor(
                        text: $state.text,
                        focusVersion: state.focusVersion,
                        slashCommandsEnabled: true,
                        slashApplyRequest: slashApplyRequest,
                        configuration: editorConfiguration,
                        callbacks: sendEditorCallbacks
                    )
                } else {
                    MarkdownTextEditor(
                        text: $workspaceText,
                        focusVersion: state.focusVersion,
                        slashCommandsEnabled: true,
                        slashApplyRequest: slashApplyRequest,
                        configuration: editorConfiguration,
                        callbacks: notesEditorCallbacks
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MuxyTheme.bg)

            if showsPlaceholder {
                placeholder
            }

            if let activeSlashContext = slashContext {
                let commands = filteredSlashCommands(for: activeSlashContext)
                SlashCommandMenuView(
                    commands: commands,
                    selectedCommandID: selectedSlashCommandID(in: commands),
                    onSelect: { command in
                        applySlashCommand(command, replaceRange: activeSlashContext.replaceRange)
                    }
                )
                .padding(.horizontal, 12)
                .padding(.top, 36)
            }
        }
    }

    private var showsPlaceholder: Bool {
        switch mode {
        case .send:
            state.text.isEmpty
        case .notes:
            workspaceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.symbolName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
            Text(headerTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MuxyTheme.fg)
            Spacer(minLength: 8)
            if mode == .send {
                Button(action: toggleBroadcast) {
                    Image(systemName: broadcastToggleIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(broadcast ? MuxyTheme.accent : MuxyTheme.fgMuted)
                }
                .buttonStyle(RichInputToolbarButtonStyle())
                .accessibilityLabel(broadcastToggleLabel)
                .help(broadcastToggleLabel)
                Button(action: toggleFloating) {
                    Image(systemName: pinToggleIcon)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(RichInputToolbarButtonStyle())
                .accessibilityLabel(pinToggleLabel)
                .help(pinToggleLabel)
                Button(action: togglePosition) {
                    Image(systemName: positionToggleIcon)
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(RichInputToolbarButtonStyle())
                .accessibilityLabel(positionToggleLabel)
                .help(positionToggleLabel)
            }
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(RichInputToolbarButtonStyle())
            .accessibilityLabel("Close")
            .help("Close")
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(MuxyTheme.bg)
    }

    private var headerTitle: String {
        switch mode {
        case .send:
            "Rich Input"
        case .notes:
            "Notes"
        }
    }

    private func persistDraft() {
        RichInputDraftStore.shared.scheduleSave(state.draft, for: worktreeKey)
    }

    private func persistWorkspace() {
        guard projectID != nil else { return }
        inspectorStore.updateWorkspace(workspaceText)
    }

    private func syncWorkspaceFromStore() {
        inspectorStore.selectProject(projectID)
        workspaceText = inspectorStore.workspaceMarkdown
    }

    private var editorConfiguration: MarkdownTextEditor.Configuration {
        MarkdownTextEditor.Configuration(
            font: resolvedFont,
            insets: NSSize(width: 12, height: 10),
            lineWrapping: true,
            grabsFirstResponderOnAppear: true,
            lineHeightMultiplier: editorSettings.richInputLineHeightMultiplier
        )
    }

    private var resolvedFont: NSFont {
        NSFont(name: editorSettings.richInputFontFamily, size: clampedFontSize)
            ?? .monospacedSystemFont(ofSize: clampedFontSize, weight: .regular)
    }

    private var sendEditorCallbacks: MarkdownTextEditor.Callbacks {
        MarkdownTextEditor.Callbacks(
            onSubmit: { onSubmit(true) },
            onSubmitWithoutReturn: { onSubmit(false) },
            onIncreaseFontSize: increaseFontSize,
            onDecreaseFontSize: decreaseFontSize,
            onPasteImageData: { data in
                guard let url = RichInputImageStorage.write(imageData: data) else { return }
                insertImagePlaceholder(for: url)
            },
            onPasteFileURL: { url in
                guard !state.fileAttachments.contains(url) else { return }
                state.fileAttachments.append(url)
            },
            onSlashCommandContextChange: { context in
                if context != nil {
                    slashSelectedIndex = 0
                }
                slashContext = context
            },
            onSlashMenuKey: handleSlashMenuKey
        )
    }

    private var notesEditorCallbacks: MarkdownTextEditor.Callbacks {
        MarkdownTextEditor.Callbacks(
            onIncreaseFontSize: increaseFontSize,
            onDecreaseFontSize: decreaseFontSize,
            onSlashCommandContextChange: { context in
                if context != nil {
                    slashSelectedIndex = 0
                }
                slashContext = context
            },
            onSlashMenuKey: handleSlashMenuKey
        )
    }

    private func filteredSlashCommands(for context: MarkdownSlashCommandContext) -> [MarkdownSlashCommand] {
        MarkdownSlashCommandSession.filteredCommands(query: context.query)
    }

    private func selectedSlashCommandID(in commands: [MarkdownSlashCommand]) -> String? {
        guard !commands.isEmpty else { return nil }
        let index = MarkdownSlashCommandSelection.clampedIndex(slashSelectedIndex, commandCount: commands.count)
        return commands[index].id
    }

    private func handleSlashMenuKey(_ key: MarkdownSlashMenuKey) -> Bool {
        guard let activeSlashContext = slashContext else { return false }
        let commands = filteredSlashCommands(for: activeSlashContext)
        switch key {
        case .up:
            slashSelectedIndex = MarkdownSlashCommandSelection.movedIndex(
                from: slashSelectedIndex,
                delta: -1,
                commandCount: commands.count
            )
            return true
        case .down:
            slashSelectedIndex = MarkdownSlashCommandSelection.movedIndex(
                from: slashSelectedIndex,
                delta: 1,
                commandCount: commands.count
            )
            return true
        case .confirm:
            guard !commands.isEmpty else { return true }
            let index = MarkdownSlashCommandSelection.clampedIndex(slashSelectedIndex, commandCount: commands.count)
            applySlashCommand(commands[index], replaceRange: activeSlashContext.replaceRange)
            return true
        case .cancel:
            slashContext = nil
            slashSelectedIndex = 0
            return true
        }
    }

    private func applySlashCommand(_ command: MarkdownSlashCommand, replaceRange: NSRange) {
        slashApplyRequest = MarkdownSlashCommandApplyRequest(
            token: UUID(),
            command: command,
            replaceRange: replaceRange
        )
        slashContext = nil
        slashSelectedIndex = 0
    }

    private var clampedFontSize: CGFloat {
        let bounded = min(max(fontSize, RichInputPreferences.minFontSize), RichInputPreferences.maxFontSize)
        return CGFloat(bounded)
    }

    private var placeholder: some View {
        Text(placeholderText)
            .font(.system(size: clampedFontSize))
            .foregroundStyle(MuxyTheme.fgMuted.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .allowsHitTesting(false)
    }

    private var placeholderText: String {
        switch mode {
        case .send:
            "Type something… type / for blocks"
        case .notes:
            "Notes and tasks… type / for blocks"
        }
    }

    private var positionToggleIcon: String {
        switch position {
        case .right: "rectangle.bottomhalf.inset.filled"
        case .bottom: "rectangle.righthalf.inset.filled"
        }
    }

    private var positionToggleLabel: String {
        switch position {
        case .right: "Move to Bottom"
        case .bottom: "Move to Right"
        }
    }

    private func togglePosition() {
        position = position == .right ? .bottom : .right
    }

    private var pinToggleIcon: String {
        floating ? "pin" : "pin.slash"
    }

    private var pinToggleLabel: String {
        floating ? "Dock Panel" : "Float Panel"
    }

    private func toggleFloating() {
        floating.toggle()
    }

    private var broadcastToggleIcon: String {
        broadcast ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash"
    }

    private var broadcastToggleLabel: String {
        broadcast ? "Broadcast On — Send to All Split Panes" : "Broadcast Off — Send to Active Pane"
    }

    private func toggleBroadcast() {
        broadcast.toggle()
    }

    private func increaseFontSize() {
        fontSize = min(RichInputPreferences.maxFontSize, fontSize + RichInputPreferences.fontStep)
    }

    private func decreaseFontSize() {
        fontSize = max(RichInputPreferences.minFontSize, fontSize - RichInputPreferences.fontStep)
    }

    private func insertImagePlaceholder(for url: URL) {
        let placeholder = state.nextImagePlaceholder(for: url)
        state.text.append(placeholder)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var consumed = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let url: URL? = if let url = item as? URL {
                        url
                    } else if let data = item as? Data {
                        URL(dataRepresentation: data, relativeTo: nil)
                    } else {
                        nil
                    }
                    guard let url else { return }
                    Task { @MainActor in
                        if !state.fileAttachments.contains(url) {
                            state.fileAttachments.append(url)
                        }
                    }
                }
                consumed = true
                continue
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data, let url = RichInputImageStorage.write(imageData: data) else { return }
                    Task { @MainActor in
                        insertImagePlaceholder(for: url)
                    }
                }
                consumed = true
            }
        }
        return consumed
    }
}

private struct AttachmentChipsView: View {
    let attachments: [URL]
    let onRemove: (URL) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(attachments, id: \.self) { url in
                    AttachmentChip(url: url, onRemove: { onRemove(url) })
                }
            }
        }
    }
}

private struct AttachmentChip: View {
    let url: URL
    let onRemove: () -> Void

    private var isImage: Bool {
        guard let utType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return utType.conforms(to: .image)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isImage ? "photo" : "doc")
                .font(.system(size: 10))
                .foregroundStyle(MuxyTheme.fgMuted)
            Text(url.lastPathComponent)
                .font(.system(size: 11))
                .foregroundStyle(MuxyTheme.fg)
                .lineLimit(1)
                .truncationMode(.middle)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fgMuted)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove attachment")
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(MuxyTheme.surface)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(MuxyTheme.border, lineWidth: 1))
    }
}
