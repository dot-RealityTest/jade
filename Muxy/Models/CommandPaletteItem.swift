import Foundation

enum CommandPaletteSection: String, CaseIterable {
    case app = "App"
    case remote = "Remote Spaces"
    case snippet = "Snippets"
    case file = "Files"
    case worktree = "Worktrees"

    var sortOrder: Int {
        switch self {
        case .app: 0
        case .remote: 1
        case .snippet: 2
        case .file: 3
        case .worktree: 4
        }
    }
}

struct CommandPaletteItem: Identifiable, Equatable {
    enum Target: Equatable {
        case shortcut(ShortcutAction)
        case remote(UUID)
        case snippet(UUID)
        case file(String)
        case worktree(projectID: UUID, worktreeID: UUID)
    }

    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let section: CommandPaletteSection
    let searchText: String
    let target: Target

    init(
        id: String,
        title: String,
        subtitle: String,
        symbolName: String,
        section: CommandPaletteSection,
        searchText: String = "",
        target: Target
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.section = section
        self.searchText = searchText
        self.target = target
    }

    var normalizedSearchText: String {
        [title, subtitle, section.rawValue, searchText].joined(separator: " ").lowercased()
    }

    func matches(query: String) -> Bool {
        let terms = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: " ")
        guard !terms.isEmpty else { return true }
        return terms.allSatisfy { normalizedSearchText.contains($0) }
    }

    static func filter(_ items: [CommandPaletteItem], query: String) -> [CommandPaletteItem] {
        items
            .filter { $0.matches(query: query) }
            .sorted { lhs, rhs in
                if lhs.section.sortOrder != rhs.section.sortOrder {
                    return lhs.section.sortOrder < rhs.section.sortOrder
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }
}
