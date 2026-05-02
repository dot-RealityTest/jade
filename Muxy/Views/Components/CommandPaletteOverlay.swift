import SwiftUI

struct CommandPaletteOverlay: View {
    let appItems: [CommandPaletteItem]
    let remoteSpaces: [RemoteSpace]
    let activeRemoteSpace: RemoteSpace?
    let snippetScope: SnippetScope
    let projectPath: String?
    let worktreeItems: [WorktreeSwitcherItem]
    let onSelect: (CommandPaletteItem) -> Void
    let onDismiss: () -> Void

    @State private var snippetsStore = SnippetsStore.shared
    @State private var pendingConfirmationID: String?

    var body: some View {
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
            footer: AnyView(CommandPaletteFooter(isConfirming: pendingConfirmationID != nil))
        )
        .onAppear {
            snippetsStore.selectScope(snippetScope)
        }
        .onChange(of: snippetScope) { _, scope in
            snippetsStore.selectScope(scope)
        }
    }

    private func handleSelect(_ item: CommandPaletteItem) {
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
        async let fileItems = fileResults(query: query)
        let baseItems = await MainActor.run {
            appItems
                + remoteCommandItems()
                + remoteItems()
                + snippetItems()
                + worktreeCommandItems()
        }
        return await CommandPaletteItem.filter(
            baseItems + fileItems,
            query: query,
            sectionOrder: sectionOrder
        )
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
        worktreeItems.map { item in
            CommandPaletteItem(
                id: "worktree-\(item.projectID.uuidString)-\(item.worktree.id.uuidString)",
                title: "Switch to \(item.displayName)",
                subtitle: item.branchSubtitle.map { "\($0) · \(item.projectName)" } ?? item.projectName,
                symbolName: "point.3.connected.trianglepath.dotted",
                section: .worktree,
                searchText: item.searchKey,
                target: .worktree(projectID: item.projectID, worktreeID: item.worktree.id)
            )
        }
    }

    private func fileResults(query: String) async -> [CommandPaletteItem] {
        guard let projectPath else { return [] }
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
}
