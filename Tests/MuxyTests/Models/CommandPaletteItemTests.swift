import Foundation
import Testing

@testable import Muxy

@Suite("CommandPaletteItem")
struct CommandPaletteItemTests {
    @Test("filter matches title subtitle section and search text")
    func filterMatchesFields() {
        let items = [
            item(title: "Source Control", subtitle: "Open git status", section: .app, searchText: "vcs"),
            item(title: "Update Linux", subtitle: "sudo apt update", section: .remoteCommand, searchText: "packages"),
            item(title: "Open Alienware", subtitle: "kika@192.168.1.171", section: .remote, searchText: "nvidia"),
            item(title: "GPU Console", subtitle: "nvtop", section: .snippet, searchText: "linux gpu"),
            item(title: "Generate shell command", subtitle: "Review a safe command", section: .app, searchText: "find large files"),
            item(title: "README.md", subtitle: "docs/README.md", section: .file, searchText: "/tmp/docs/README.md"),
            item(title: "Switch to feature", subtitle: "muxy", section: .worktree, searchText: "feature branch"),
        ]

        #expect(CommandPaletteItem.filter(items, query: "vcs").map(\.title) == ["Source Control"])
        #expect(CommandPaletteItem.filter(items, query: "packages").map(\.title) == ["Update Linux"])
        #expect(CommandPaletteItem.filter(items, query: "alien nvidia").map(\.title) == ["Open Alienware"])
        #expect(CommandPaletteItem.filter(items, query: "linux gpu").map(\.title) == ["GPU Console"])
        #expect(CommandPaletteItem.filter(items, query: "large files").map(\.title) == ["Generate shell command"])
        #expect(CommandPaletteItem.filter(items, query: "readme").map(\.title) == ["README.md"])
        #expect(CommandPaletteItem.filter(items, query: "feature").map(\.title) == ["Switch to feature"])
    }

    @Test("filter keeps static section ordering")
    func filterKeepsSectionOrdering() {
        let items = [
            item(title: "z", section: .worktree),
            item(title: "z", section: .file),
            item(title: "z", section: .snippet),
            item(title: "z", section: .remote),
            item(title: "z", section: .mcp),
            item(title: "z", section: .app),
        ]

        #expect(CommandPaletteItem.filter(items, query: "").map(\.section) == [
            .app,
            .mcp,
            .remote,
            .snippet,
            .file,
            .worktree,
        ])
    }

    @Test("filter marks the first visible item in each section")
    func filterMarksSectionHeaders() {
        let items = [
            item(title: "New Tab", section: .app),
            item(title: "Open Project", section: .app),
            item(title: "Open Zen", section: .remote),
            item(title: "Open Alienware", section: .remote),
        ]

        let result = CommandPaletteItem.filter(items, query: "")

        #expect(result.map(\.title) == ["New Tab", "Open Project", "Open Alienware", "Open Zen"])
        #expect(result.map(\.showsSectionHeader) == [true, false, true, false])
    }

    @Test("filter supports remote space ordering")
    func filterSupportsRemoteSpaceOrdering() {
        let items = [
            item(title: "New Tab", section: .app),
            item(title: "Open Alienware", section: .remote),
            item(title: "Update Linux", section: .remoteCommand),
            item(title: "GPU Console", section: .snippet),
            item(title: "README.md", section: .file),
        ]

        #expect(CommandPaletteItem.filter(
            items,
            query: "",
            sectionOrder: CommandPaletteSection.remoteSpaceOrder
        ).map(\.section) == [.remoteCommand, .snippet, .remote, .app, .file])
    }

    @Test("filter preserves priority inside a section")
    func filterPreservesPriorityInsideSection() {
        let items = [
            item(title: "Reboot", section: .remoteCommand, sortPriority: 12),
            item(title: "Open SSH Session", section: .remoteCommand, sortPriority: 0),
            item(title: "Copy SSH Command", section: .remoteCommand, sortPriority: 1),
        ]

        #expect(CommandPaletteItem.filter(items, query: "").map(\.title) == [
            "Open SSH Session",
            "Copy SSH Command",
            "Reboot",
        ])
    }

    @Test("filter ranks stronger matches inside a section")
    func filterRanksStrongerMatchesInsideSection() {
        let items = [
            item(title: "Open Project", subtitle: "Git workspace", section: .app),
            item(title: "Git", section: .app),
            item(title: "Source Control", subtitle: "Git status", section: .app),
            item(title: "Recent Files", section: .app, searchText: "git history"),
        ]

        #expect(CommandPaletteItem.filter(items, query: "git").map(\.title) == [
            "Git",
            "Open Project",
            "Source Control",
            "Recent Files",
        ])
    }

    @Test("local command actions expose search aliases")
    func localCommandActionsExposeSearchAliases() {
        #expect(LocalCommandPaletteAction.upgradeHomebrew.searchText.contains("homebrew"))
        #expect(LocalCommandPaletteAction.upgradeHomebrew.command(ollamaModel: "").contains("brew update"))
        #expect(LocalCommandPaletteAction.ollamaList.searchText.contains("ollama"))
        #expect(LocalCommandPaletteAction.ollamaPull.command(ollamaModel: "mistral").contains("ollama pull"))
        #expect(LocalCommandPaletteAction.ollamaRun.command(ollamaModel: "mistral").contains("ollama run"))
    }

    @Test("remote command actions expose safety and aliases")
    func remoteCommandActionsExposeSafetyAndAliases() {
        #expect(RemoteCommandPaletteAction.reboot.requiresConfirmation)
        #expect(RemoteCommandPaletteAction.powerOff.requiresConfirmation)
        #expect(!RemoteCommandPaletteAction.updateLinux.requiresConfirmation)
        #expect(RemoteCommandPaletteAction.reboot.searchText.contains("restart"))
        #expect(RemoteCommandPaletteAction.powerOff.searchText.contains("shutdown"))
        #expect(RemoteCommandPaletteAction.updateLinux.searchText.contains("limnux"))
        #expect(RemoteCommandPaletteAction.gpuStatus.searchText.contains("alienware"))
    }

    @Test("remote command tab title includes the active space")
    func remoteCommandTabTitleIncludesActiveSpace() {
        let space = RemoteSpace(name: "Zen", user: "kika", host: "100.86.62.100")

        #expect(RemoteCommandPaletteAction.updateLinux.tabTitle(for: space) == "Zen · Update Linux")
    }

    @Test("filter keeps confirmation flag when marking sections")
    func filterKeepsConfirmationFlagWhenMarkingSections() {
        let items = [
            item(title: "Reboot", section: .remoteCommand, requiresConfirmation: true),
        ]

        #expect(CommandPaletteItem.filter(items, query: "").first?.requiresConfirmation == true)
    }

    @Test("file search stays closed until there is a query")
    func fileSearchStaysClosedUntilThereIsAQuery() {
        #expect(!CommandPaletteFileSearchPolicy.shouldSearchFiles(query: ""))
        #expect(!CommandPaletteFileSearchPolicy.shouldSearchFiles(query: "   "))
        #expect(CommandPaletteFileSearchPolicy.shouldSearchFiles(query: "readme"))
    }

    private func item(
        title: String,
        subtitle: String = "",
        section: CommandPaletteSection,
        searchText: String = "",
        sortPriority: Int = 0,
        requiresConfirmation: Bool = false
    ) -> CommandPaletteItem {
        CommandPaletteItem(
            id: "\(section.rawValue)-\(title)",
            title: title,
            subtitle: subtitle,
            symbolName: "circle",
            section: section,
            searchText: searchText,
            target: .shortcut(.newTab),
            sortPriority: sortPriority,
            requiresConfirmation: requiresConfirmation
        )
    }
}
