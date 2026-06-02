import SwiftUI

struct MainWindowCommandPaletteContext {
    var snippetsScopeMode: SnippetsScopeMode
    var activeProjectName: String?
    var ollamaModel: String
}

enum MainWindowCommandPaletteBuilder {
    static func appItems(context: MainWindowCommandPaletteContext) -> [CommandPaletteItem] {
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
        ] + snippetsScopeItems(context: context) + [
            commandItem(
                .toggleSnippetsScope,
                symbolName: "curlybraces",
                subtitle: snippetsScopeToggleSubtitle(context: context),
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
        ] + localCommandItems(ollamaModel: context.ollamaModel) + [
            commandItem(
                .reloadConfig,
                symbolName: "arrow.clockwise",
                subtitle: "Reload terminal configuration",
                aliases: ["refresh", "ghostty", "config"],
                sortPriority: 53
            ),
        ]
    }

    private static func snippetsScopeItems(context: MainWindowCommandPaletteContext) -> [CommandPaletteItem] {
        let mode = context.snippetsScopeMode
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
                subtitle: snippetsProjectScopeSubtitle(context: context),
                symbolName: "curlybraces",
                section: .app,
                searchText: "snippets project workspace local scope mode",
                target: .snippetsScope(.project),
                sortPriority: 18
            ),
        ]
    }

    private static func snippetsScopeToggleSubtitle(context: MainWindowCommandPaletteContext) -> String {
        switch context.snippetsScopeMode {
        case .general:
            if context.activeProjectName == nil {
                return "Switch to project snippets when a project is open"
            }
            return "Switch to project-specific snippets"
        case .project:
            return "Switch to general snippets shared across projects"
        }
    }

    private static func snippetsProjectScopeSubtitle(context: MainWindowCommandPaletteContext) -> String {
        let mode = context.snippetsScopeMode
        guard let name = context.activeProjectName else {
            return "Select a project first"
        }
        if mode == .project {
            return "Active · \(name)"
        }
        return "Use snippets for \(name) only"
    }

    private static func localCommandItems(ollamaModel: String) -> [CommandPaletteItem] {
        LocalCommandPaletteAction.allCases.map { action in
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

    private static func commandItem(
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
}
