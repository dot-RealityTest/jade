import Foundation

struct MCPToolDescriptor: Identifiable, Equatable, Codable {
    let name: String
    let description: String

    var id: String { name }
}

enum ObsidianMCPToolCatalog {
    static let builtIn: [MCPToolDescriptor] = [
        MCPToolDescriptor(name: "configure_vault", description: "Set or change the vault path"),
        MCPToolDescriptor(name: "get_note", description: "Read one markdown note by vault-relative path"),
        MCPToolDescriptor(name: "create_note", description: "Create a new markdown note with optional metadata"),
        MCPToolDescriptor(name: "update_note", description: "Update note content and/or frontmatter"),
        MCPToolDescriptor(name: "delete_note", description: "Delete a markdown note"),
        MCPToolDescriptor(name: "list_notes", description: "List notes in the vault or a folder"),
        MCPToolDescriptor(name: "search_notes", description: "Search note title, content, and tags"),
        MCPToolDescriptor(name: "get_all_tags", description: "List unique tags from frontmatter and inline tags"),
        MCPToolDescriptor(name: "get_backlinks", description: "Find notes that link to a note"),
        MCPToolDescriptor(name: "get_note_links", description: "Extract wikilinks from a note"),
        MCPToolDescriptor(name: "create_folder", description: "Create a folder inside the vault"),
        MCPToolDescriptor(name: "get_folder_structure", description: "Return the vault folder tree"),
    ]

    static func parseListToolsResponse(_ result: Any) -> [MCPToolDescriptor] {
        guard let dictionary = result as? [String: Any],
              let tools = dictionary["tools"] as? [[String: Any]]
        else {
            return []
        }

        return tools.compactMap { tool in
            guard let name = tool["name"] as? String else { return nil }
            let description = tool["description"] as? String
                ?? (tool["title"] as? String)
                ?? name
            return MCPToolDescriptor(name: name, description: description)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func merged(discovered: [MCPToolDescriptor]) -> [MCPToolDescriptor] {
        guard !discovered.isEmpty else { return builtIn }
        var seen = Set<String>()
        var merged: [MCPToolDescriptor] = []
        for tool in discovered + builtIn where seen.insert(tool.name).inserted {
            merged.append(tool)
        }
        return merged.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

enum ObsidianVaultPathValidator {
    static func normalizedPath(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return URL(fileURLWithPath: trimmed, isDirectory: true).standardizedFileURL.path(percentEncoded: false)
    }

    static func validationMessage(for path: String) -> String? {
        let normalized = normalizedPath(path)
        guard !normalized.isEmpty else { return "Choose an Obsidian vault folder." }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: normalized, isDirectory: &isDirectory) else {
            return "Vault folder does not exist."
        }
        guard isDirectory.boolValue else { return "Vault path must be a folder." }
        return nil
    }
}
