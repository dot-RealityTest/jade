import Foundation

enum CommandPaletteSection: String, CaseIterable {
    case app = "App"
    case remote = "Remote Spaces"
    case snippet = "Snippets"
    case file = "Files"
    case worktree = "Worktrees"

    var sortOrder: Int {
        Self.defaultOrder.firstIndex(of: self) ?? Self.defaultOrder.count
    }

    static let defaultOrder: [CommandPaletteSection] = [.app, .remote, .snippet, .file, .worktree]
    static let remoteSpaceOrder: [CommandPaletteSection] = [.snippet, .remote, .app, .file, .worktree]
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
    let showsSectionHeader: Bool

    init(
        id: String,
        title: String,
        subtitle: String,
        symbolName: String,
        section: CommandPaletteSection,
        searchText: String = "",
        target: Target,
        showsSectionHeader: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.section = section
        self.searchText = searchText
        self.target = target
        self.showsSectionHeader = showsSectionHeader
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

    static func filter(
        _ items: [CommandPaletteItem],
        query: String,
        sectionOrder: [CommandPaletteSection] = CommandPaletteSection.defaultOrder
    ) -> [CommandPaletteItem] {
        let sortedItems = items
            .filter { $0.matches(query: query) }
            .sorted { lhs, rhs in
                let lhsOrder = sectionOrder.firstIndex(of: lhs.section) ?? sectionOrder.count
                let rhsOrder = sectionOrder.firstIndex(of: rhs.section) ?? sectionOrder.count
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        return markedSectionStarts(sortedItems)
    }

    private static func markedSectionStarts(_ items: [CommandPaletteItem]) -> [CommandPaletteItem] {
        var seenSections: Set<CommandPaletteSection> = []
        return items.map { item in
            let isFirst = !seenSections.contains(item.section)
            seenSections.insert(item.section)
            return item.withSectionHeader(isFirst)
        }
    }

    private func withSectionHeader(_ isVisible: Bool) -> CommandPaletteItem {
        CommandPaletteItem(
            id: id,
            title: title,
            subtitle: subtitle,
            symbolName: symbolName,
            section: section,
            searchText: searchText,
            target: target,
            showsSectionHeader: isVisible
        )
    }
}
