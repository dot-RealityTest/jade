import os
import SwiftUI

private let paletteLogger = Logger(subsystem: "app.muxy", category: "CommandPalette")

struct CommandPaletteOverlay: View {
    let appItems: [CommandPaletteItem]
    let remoteSpaces: [RemoteSpace]
    let activeRemoteSpace: RemoteSpace?
    let snippetScope: SnippetScope
    let projectPath: String?
    let worktreeOpenerItems: [OpenerItem]
    let naturalCommandContext: NaturalCommandContext
    let onSelect: (CommandPaletteItem) -> Void
    let onRunNaturalCommand: (NaturalCommandPlan) -> Void
    let onSaveNaturalCommand: (NaturalCommandPlan) -> Void
    let onDismiss: () -> Void

    @State private var snippetsStore = SnippetsStore.shared
    @State private var pendingConfirmationID: String?
    @State private var naturalCommandRequest: NaturalCommandRequest?
    @State private var cachedBaseItems: [CommandPaletteItem] = []
    @State private var cachedBaseItemsSignature: Int = 0
    private let naturalCommandGenerator = NaturalCommandCoordinator.live()

    var body: some View {
        Group {
            if let naturalCommandRequest {
                NaturalCommandReviewView(
                    request: naturalCommandRequest,
                    generator: naturalCommandGenerator,
                    onRun: onRunNaturalCommand,
                    onSave: onSaveNaturalCommand,
                    onBack: { self.naturalCommandRequest = nil },
                    onDismiss: {
                        self.naturalCommandRequest = nil
                        onDismiss()
                    }
                )
            } else {
                PaletteOverlay<CommandPaletteItem>(
                    placeholder: "Search commands, spaces, snippets, files...",
                    emptyLabel: "No commands",
                    noMatchLabel: "No matching commands",
                    search: { query in await search(query: query) },
                    onSelect: handleSelect,
                    onDismiss: {
                        pendingConfirmationID = nil
                        onDismiss()
                    },
                    row: { item, isHighlighted in
                        AnyView(CommandPaletteRow(
                            item: item,
                            isHighlighted: isHighlighted,
                            isConfirming: pendingConfirmationID == item.id
                        ))
                    },
                    footer: AnyView(CommandPaletteFooter(isConfirming: pendingConfirmationID != nil)),

                    debounceDelay: { query in
                        CommandPaletteFileSearchPolicy.shouldSearchFiles(query: query)
                            ? .milliseconds(90)
                            : .milliseconds(40)
                    }
                )
            }
        }
        .onAppear {
            snippetsStore.selectScope(snippetScope)
        }
        .onChange(of: snippetScope) { _, scope in
            snippetsStore.selectScope(scope)
        }
    }

    private func handleSelect(_ item: CommandPaletteItem) {
        if case let .naturalCommand(prompt) = item.target {
            pendingConfirmationID = nil
            naturalCommandRequest = NaturalCommandRequest(
                prompt: prompt,
                context: naturalCommandContext
            )
            return
        }
        guard item.requiresConfirmation else {
            pendingConfirmationID = nil
            onSelect(item)
            return
        }
        guard pendingConfirmationID == item.id else {
            pendingConfirmationID = item.id
            return
        }
        pendingConfirmationID = nil
        onSelect(item)
    }

    private func search(query: String) async -> [CommandPaletteItem] {
        let clock = ContinuousClock()
        let start = clock.now
        async let fileItems = fileResults(query: query)
        let baseItems = loadBaseItems()
        let shouldShowGenerator = await shouldShowNaturalCommandItem(query: query, baseItems: baseItems)
        let naturalItems = shouldShowGenerator ? [naturalCommandItem(query: query)] : []
        let filtered = await CommandPaletteItem.filter(
            naturalItems + baseItems + fileItems,
            query: query,
            sectionOrder: sectionOrder
        )
        let elapsed = start.duration(to: clock.now)
        if elapsed > .milliseconds(20) {
            let elapsedDesc = String(describing: elapsed)
            paletteLogger.debug(
                "Palette search for '\(query, privacy: .public)' returned \(filtered.count) items in \(elapsedDesc, privacy: .public)"
            )
        }
        return filtered
    }

    @MainActor
    private func loadBaseItems() -> [CommandPaletteItem] {
        var hasher = Hasher()
        hasher.combine(appItems.count)
        hasher.combine(remoteSpaces.count)
        hasher.combine(worktreeOpenerItems.count)
        hasher.combine(snippetsStore.snippets.count)
        hasher.combine(activeRemoteSpace?.id)
        let signature = hasher.finalize()
        if signature == cachedBaseItemsSignature {
            return cachedBaseItems
        }
        let updated = appItems
            + remoteCommandItems()
            + remoteItems()
            + snippetItems()
            + worktreeCommandItems()
        cachedBaseItemsSignature = signature
        cachedBaseItems = updated
        return updated
    }

    @MainActor
    private func remoteCommandItems() -> [CommandPaletteItem] {
        guard let activeRemoteSpace else { return [] }
        return RemoteCommandPaletteAction.allCases
            .filter { $0.isAvailable(for: activeRemoteSpace) }
            .map { action in
                CommandPaletteItem(
                    id: "remote-command-\(activeRemoteSpace.id.uuidString)-\(action.rawValue)",
                    title: action.title,
                    subtitle: action.subtitle,
                    symbolName: action.symbolName,
                    section: .remoteCommand,
                    searchText: [activeRemoteSpace.displayName, activeRemoteSpace.connectionSummary, action.searchText]
                        .joined(separator: " "),
                    target: .remoteCommand(action),
                    sortPriority: action.sortPriority,
                    requiresConfirmation: action.requiresConfirmation
                )
            }
    }

    @MainActor
    private func remoteItems() -> [CommandPaletteItem] {
        remoteSpaces.map { space in
            CommandPaletteItem(
                id: "remote-\(space.id.uuidString)",
                title: "Open \(space.displayName)",
                subtitle: space.connectionSummary,
                symbolName: "display",
                section: .remote,
                searchText: [space.displayName, space.connectionSummary, space.connectionCommand].joined(separator: " "),
                target: .remote(space.id)
            )
        }
    }

    @MainActor
    private func snippetItems() -> [CommandPaletteItem] {
        snippetsStore.snippets.map { snippet in
            CommandPaletteItem(
                id: "snippet-\(snippet.id.uuidString)",
                title: snippet.displayName,
                subtitle: snippet.trimmedCommand,
                symbolName: "curlybraces",
                section: .snippet,
                searchText: (snippet.tags + [snippet.trimmedDescription]).joined(separator: " "),
                target: .snippet(snippet.id)
            )
        }
    }

    private func worktreeCommandItems() -> [CommandPaletteItem] {
        worktreeOpenerItems.compactMap { item in
            guard case let .worktree(worktree) = item else { return nil }
            return CommandPaletteItem(
                id: "worktree-\(worktree.projectID.uuidString)-\(worktree.worktreeID.uuidString)",
                title: "Switch to \(item.title)",
                subtitle: item.subtitle ?? item.title,
                symbolName: "point.3.connected.trianglepath.dotted",
                section: .worktree,
                searchText: item.searchKey,
                target: .worktree(projectID: worktree.projectID, worktreeID: worktree.worktreeID)
            )
        }
    }

    private func fileResults(query: String) async -> [CommandPaletteItem] {
        guard let projectPath, CommandPaletteFileSearchPolicy.shouldSearchFiles(query: query) else { return [] }
        let results = await FileSearchService.search(query: query, in: projectPath)
        return results.map { result in
            CommandPaletteItem(
                id: "file-\(result.absolutePath)",
                title: result.fileName,
                subtitle: result.relativePath,
                symbolName: fileIcon(for: result.absolutePath),
                section: .file,
                searchText: result.absolutePath,
                target: .file(result.absolutePath)
            )
        }
    }

    private func fileIcon(for path: String) -> String {
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case "swift": "swift"
        case "js",
             "jsx",
             "mjs": "j.square"
        case "ts",
             "tsx",
             "mts": "t.square"
        case "py": "p.square"
        case "json": "curlybraces"
        case "html",
             "htm": "chevron.left.forwardslash.chevron.right"
        case "css",
             "scss": "paintbrush"
        case "md",
             "markdown": "doc.richtext"
        case "yaml",
             "yml",
             "toml": "gearshape"
        case "sh",
             "bash",
             "zsh": "terminal"
        default: "doc.text"
        }
    }

    private var sectionOrder: [CommandPaletteSection] {
        snippetScope.id.hasPrefix("remote-") ? CommandPaletteSection.remoteSpaceOrder : CommandPaletteSection.defaultOrder
    }

    private func shouldShowNaturalCommandItem(query: String, baseItems: [CommandPaletteItem]) async -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let enabled = await MainActor.run { NaturalCommandSettings.shared.isEnabled }
        guard enabled else { return false }
        let terms = trimmed.split(separator: " ")
        guard terms.count >= 2 || ShellCommandSafetyClassifier.containsDestructiveIntent(trimmed.lowercased()) else { return false }
        return !baseItems.contains { $0.matches(query: trimmed) }
    }

    private func naturalCommandItem(query: String) -> CommandPaletteItem {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandPaletteItem(
            id: "natural-command-\(trimmed)",
            title: "Generate shell command",
            subtitle: "Review a safe command for \"\(trimmed)\"",
            symbolName: "sparkles",
            section: .app,
            searchText: trimmed,
            target: .naturalCommand(trimmed),
            sortPriority: -100
        )
    }
}

private struct CommandPaletteFooter: View {
    let isConfirming: Bool

    var body: some View {
        HStack(spacing: 12) {
            hint("Enter", isConfirming ? "Confirm" : "Run")
            hint("Esc", "Close")
            Spacer()
            Text("Actions hidden from the toolbar stay here")
                .font(.system(size: 10))
                .foregroundStyle(MuxyTheme.fgDim)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 4))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(MuxyTheme.fgDim)
        }
    }
}

private struct CommandPaletteRow: View {
    let item: CommandPaletteItem
    let isHighlighted: Bool
    let isConfirming: Bool
    @State private var hovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if item.showsSectionHeader {
                HStack(spacing: 8) {
                    Text(item.section.rawValue.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(sectionColor)
                    Rectangle()
                        .fill(MuxyTheme.border)
                        .frame(height: 1)
                }
                .padding(.horizontal, 12)
                .padding(.top, 9)
                .padding(.bottom, 3)
            }

            HStack(spacing: 10) {
                Image(systemName: item.symbolName)
                    .font(.system(size: 12))
                    .foregroundStyle(iconColor)
                    .frame(width: 16)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isConfirming ? confirmationTitle : item.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MuxyTheme.fg)
                        .lineLimit(1)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(isConfirming ? MuxyTheme.warning : MuxyTheme.fgDim)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(rowBackground)
        }
        .onHover { hovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isConfirming ? "Press Return to confirm" : "Press Return to run")
    }

    private var confirmationTitle: String {
        guard case let .remoteCommand(action) = item.target else { return item.title }
        return action.confirmationTitle
    }

    private var subtitle: String {
        guard case let .remoteCommand(action) = item.target, isConfirming else { return item.subtitle }
        return action.confirmationSubtitle
    }

    private var sectionColor: Color {
        item.section == .remoteCommand ? MuxyTheme.accent : MuxyTheme.fgDim
    }

    private var iconColor: Color {
        isConfirming ? MuxyTheme.warning : item.section == .remoteCommand ? MuxyTheme.accent : MuxyTheme.fgMuted
    }

    private var rowBackground: some ShapeStyle {
        if isConfirming {
            return AnyShapeStyle(MuxyTheme.warning.opacity(0.12))
        }
        if isHighlighted {
            return AnyShapeStyle(MuxyTheme.surface)
        }
        if hovered {
            return AnyShapeStyle(MuxyTheme.hover)
        }
        return AnyShapeStyle(Color.clear)
    }

    private var accessibilityLabel: String {
        let parts = [
            isConfirming ? confirmationTitle : item.title,
            subtitle,
            item.section.rawValue,
        ].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }
}
