import Foundation

@MainActor
enum ObsidianMCPService {
    static func discoverTools(settings: ObsidianMCPSettings) async -> Result<[MCPToolDescriptor], Error> {
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
            let tools = try await MCPStdioSession.listTools(configuration: configuration)
            return .success(ObsidianMCPToolCatalog.merged(discovered: tools))
        } catch {
            return .failure(error)
        }
    }

    static func runTool(
        _ toolName: String,
        arguments: [String: Any],
        settings: ObsidianMCPSettings
    ) async -> Result<[String: Any], Error> {
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
            let encodedArguments = try JSONSerialization.data(withJSONObject: arguments)
            let response = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: toolName,
                encodedArguments: encodedArguments
            )
            return .success(response)
        } catch {
            return .failure(error)
        }
    }

    static func summaryMessage(for action: ObsidianMCPToolAction, response: [String: Any]) -> String {
        switch action {
        case .listInboxNotes:
            if let count = response["count"] as? Int {
                return "Inbox contains \(count) notes."
            }
            if let notes = response["notes"] as? [[String: Any]] {
                return "Inbox contains \(notes.count) notes."
            }
            return "Inbox listed successfully."
        case .searchNotes:
            if let count = response["count"] as? Int {
                return "Found \(count) matching notes."
            }
            if let results = response["results"] as? [[String: Any]] {
                return "Found \(results.count) matching notes."
            }
            if let notes = response["notes"] as? [[String: Any]] {
                return "Found \(notes.count) matching notes."
            }
            return "Search completed."
        case .getAllTags:
            if let tags = response["tags"] as? [String] {
                return "Found \(tags.count) tags."
            }
            return "Tags fetched."
        case .getFolderStructure:
            return "Vault folder structure fetched."
        case .sendCapture,
             .openSettings:
            return "Done."
        }
    }
}
