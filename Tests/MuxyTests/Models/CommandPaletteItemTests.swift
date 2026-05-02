import Foundation
import Testing

@testable import Muxy

@Suite("CommandPaletteItem")
struct CommandPaletteItemTests {
    @Test("filter matches title subtitle section and search text")
    func filterMatchesFields() {
        let items = [
            item(title: "Source Control", subtitle: "Open git status", section: .app, searchText: "vcs"),
            item(title: "Open Alienware", subtitle: "kika@192.168.1.171", section: .remote, searchText: "nvidia"),
            item(title: "GPU Console", subtitle: "nvtop", section: .snippet, searchText: "linux gpu"),
            item(title: "README.md", subtitle: "docs/README.md", section: .file, searchText: "/tmp/docs/README.md"),
            item(title: "Switch to feature", subtitle: "muxy", section: .worktree, searchText: "feature branch"),
        ]

        #expect(CommandPaletteItem.filter(items, query: "vcs").map(\.title) == ["Source Control"])
        #expect(CommandPaletteItem.filter(items, query: "alien nvidia").map(\.title) == ["Open Alienware"])
        #expect(CommandPaletteItem.filter(items, query: "linux gpu").map(\.title) == ["GPU Console"])
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
            item(title: "z", section: .app),
        ]

        #expect(CommandPaletteItem.filter(items, query: "").map(\.section) == [
            .app,
            .remote,
            .snippet,
            .file,
            .worktree,
        ])
    }

    private func item(
        title: String,
        subtitle: String = "",
        section: CommandPaletteSection,
        searchText: String = ""
    ) -> CommandPaletteItem {
        CommandPaletteItem(
            id: "\(section.rawValue)-\(title)",
            title: title,
            subtitle: subtitle,
            symbolName: "circle",
            section: section,
            searchText: searchText,
            target: .shortcut(.newTab)
        )
    }
}
