import Foundation

@MainActor
struct ObsidianSendService {
    static func send(
        content: String,
        projectName: String?,
        projectPath: String? = nil,
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

        let title = ObsidianNotePathBuilder.title(from: trimmed)
        let notePath: String
        let noteContent: String
        var tags = settings.defaultTags

        if let projectName, let projectPath {
            if case let .failure(error) = await ObsidianProjectLogIndex.ensure(
                projectName: projectName,
                projectPath: projectPath,
                settings: settings
            ) {
                return .failure(error)
            }

            let projectTag = ObsidianNotePathBuilder.slugify(projectName)
            notePath = ObsidianNotePathBuilder.projectCapturePath(
                projectName: projectName,
                content: trimmed
            )
            let structured = JadeProjectContextReader.loadStructured(projectPath: projectPath)
            noteContent = JadeJourneyLogFormatter.captureNote(
                input: JadeJourneyLogFormatter.CaptureNoteInput(
                    content: trimmed,
                    projectName: projectName,
                    projectPath: projectPath,
                    structured: structured
                )
            )
            tags.append("project-capture")
            if !projectTag.isEmpty, !tags.contains(projectTag) {
                tags.append(projectTag)
            }
        } else {
            notePath = ObsidianNotePathBuilder.inboxNotePath(
                inboxFolder: settings.inboxFolder,
                titleHint: title
            )
            noteContent = trimmed
            if let projectName {
                let projectTag = ObsidianNotePathBuilder.slugify(projectName)
                if !projectTag.isEmpty, !tags.contains(projectTag) {
                    tags.append(projectTag)
                }
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
                "content": noteContent,
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
