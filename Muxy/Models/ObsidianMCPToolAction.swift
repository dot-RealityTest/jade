import Foundation

enum ObsidianMCPToolAction: String, CaseIterable, Identifiable {
    case sendCapture
    case listInboxNotes
    case searchNotes
    case getAllTags
    case getFolderStructure
    case openSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sendCapture: "Send to Obsidian"
        case .listInboxNotes: "List Obsidian Inbox Notes"
        case .searchNotes: "Search Obsidian Notes"
        case .getAllTags: "List Obsidian Tags"
        case .getFolderStructure: "Show Obsidian Vault Tree"
        case .openSettings: "Open MCP Tools Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .sendCapture: "Capture selection, rich input, or clipboard into the inbox"
        case .listInboxNotes: "List notes in the configured inbox folder"
        case .searchNotes: "Search titles, content, and tags in the vault"
        case .getAllTags: "Fetch unique tags from the vault"
        case .getFolderStructure: "Show the vault folder tree"
        case .openSettings: "Configure vault path, server, and MCP tools"
        }
    }

    var symbolName: String {
        switch self {
        case .sendCapture: "note.text.badge.plus"
        case .listInboxNotes: "tray.full"
        case .searchNotes: "magnifyingglass"
        case .getAllTags: "tag"
        case .getFolderStructure: "folder"
        case .openSettings: "puzzlepiece.extension"
        }
    }

    var searchText: String {
        switch self {
        case .sendCapture: "obsidian capture note inbox mcp send clipboard selection"
        case .listInboxNotes: "obsidian list notes inbox folder vault mcp"
        case .searchNotes: "obsidian search notes vault mcp find"
        case .getAllTags: "obsidian tags vault mcp metadata"
        case .getFolderStructure: "obsidian folders tree vault structure mcp"
        case .openSettings: "obsidian mcp settings configure vault server python"
        }
    }

    var toolName: String? {
        switch self {
        case .sendCapture: nil
        case .listInboxNotes: "list_notes"
        case .searchNotes: "search_notes"
        case .getAllTags: "get_all_tags"
        case .getFolderStructure: "get_folder_structure"
        case .openSettings: nil
        }
    }

    var requiresSearchQuery: Bool {
        self == .searchNotes
    }

    func isAvailable(for settings: ObsidianMCPSettings) -> Bool {
        switch self {
        case .openSettings:
            true
        case .sendCapture:
            settings.canSendNotes
        default:
            settings.isEnabled && settings.isVaultConfigured && settings.isServerConfigured
        }
    }
}
