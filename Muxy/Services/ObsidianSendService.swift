import Foundation

@MainActor
struct ObsidianSendService {
    static func send(
        content: String,
        projectName: String?,
        settings: ObsidianMCPSettings = ObsidianMCPSettingsStore.shared.snapshot
    ) async -> Result<String, Error> {
        guard settings.isEnabled else {
            return .failure(MCPClientError.notConfigured("Enable Obsidian MCP in Settings"))
        }
        guard settings.canSendNotes else {
            return .failure(MCPClientError.notConfigured("Configure vault, Python, and server.py in Settings"))
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(MCPClientError.notConfigured("Nothing to send"))
        }

        let notePath = ObsidianNotePathBuilder.inboxNotePath(
            inboxFolder: settings.inboxFolder,
            titleHint: ObsidianNotePathBuilder.title(from: trimmed)
        )
        let title = ObsidianNotePathBuilder.title(from: trimmed)
        var tags = settings.defaultTags
        if let projectName {
            let projectTag = ObsidianNotePathBuilder.slugify(projectName)
            if !projectTag.isEmpty, !tags.contains(projectTag) {
                tags.append(projectTag)
            }
        }

        do {
            let configuration = MCPStdioSessionConfiguration(
                pythonPath: settings.pythonPath,
                serverScriptPath: settings.serverScriptPath,
                environment: settings.serverEnvironment
            )
            let encodedArguments = try JSONSerialization.data(withJSONObject: [
                "path": notePath,
                "content": trimmed,
                "title": title,
                "tags": tags,
            ])
            let response = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: "create_note",
                encodedArguments: encodedArguments
            )
            let savedPath = response["path"] as? String ?? notePath
            return .success(savedPath)
        } catch {
            return .failure(error)
        }
    }

    static func testConnection(
        settings: ObsidianMCPSettings = ObsidianMCPSettingsStore.shared.snapshot
    ) async -> Result<Int, Error> {
        guard settings.isEnabled else {
            return .failure(MCPClientError.notConfigured("Enable Obsidian MCP first"))
        }
        guard settings.isVaultConfigured, settings.isServerConfigured else {
            return .failure(MCPClientError.notConfigured("Configure vault, Python, and server.py"))
        }

        do {
            let configuration = MCPStdioSessionConfiguration(
                pythonPath: settings.pythonPath,
                serverScriptPath: settings.serverScriptPath,
                environment: settings.serverEnvironment
            )
            let encodedArguments = try JSONSerialization.data(withJSONObject: ["folder": settings.inboxFolder])
            let response = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: "list_notes",
                encodedArguments: encodedArguments
            )
            if let count = response["count"] as? Int {
                return .success(count)
            }
            if let notes = response["notes"] as? [[String: Any]] {
                return .success(notes.count)
            }
            return .success(0)
        } catch {
            return .failure(error)
        }
    }
}
