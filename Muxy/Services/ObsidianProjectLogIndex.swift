import Foundation

enum ObsidianProjectLogIndex {
    static func vaultRelativePath(projectName: String) -> String {
        ObsidianNotePathBuilder.projectLogIndexPath(projectName: projectName)
    }

    static func exists(projectName: String, settings: ObsidianMCPSettings) -> Bool {
        let vault = ObsidianVaultPathValidator.normalizedPath(settings.vaultPath)
        guard !vault.isEmpty else { return false }
        let relative = vaultRelativePath(projectName: projectName)
        let fullPath = URL(fileURLWithPath: vault, isDirectory: true)
            .appendingPathComponent(relative)
            .path
        return FileManager.default.fileExists(atPath: fullPath)
    }

    static func ensure(
        projectName: String,
        projectPath: String,
        settings: ObsidianMCPSettings
    ) async -> Result<Void, Error> {
        guard settings.isEnabled, settings.canSendNotes else {
            return .success(())
        }

        if exists(projectName: projectName, settings: settings) {
            return .success(())
        }

        let indexPath = vaultRelativePath(projectName: projectName)
        let slug = ObsidianNotePathBuilder.slugify(projectName)
        let structured = JadeProjectContextReader.loadStructured(projectPath: projectPath)
        let content = JadeJourneyLogFormatter.projectLogIndex(
            projectName: projectName,
            projectPath: projectPath,
            structured: structured
        )

        do {
            let configuration = MCPStdioSessionConfiguration(
                pythonPath: settings.pythonPath,
                serverScriptPath: settings.serverScriptPath,
                environment: settings.serverEnvironment
            )
            var tags = settings.defaultTags
            tags.append("project-log")
            if !slug.isEmpty, !tags.contains(slug) {
                tags.append(slug)
            }

            let encodedArguments = try JSONSerialization.data(withJSONObject: [
                "path": indexPath,
                "content": content,
                "title": "\(projectName) — project log",
                "tags": tags,
            ])
            _ = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: "create_note",
                encodedArguments: encodedArguments
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
