import Foundation

@MainActor
struct ObsidianSendService {
    static func send(
        content: String,
        projectName: String?,
        projectPath: String? = nil,
        settings: ObsidianMCPSettings = ObsidianMCPSettingsStore.shared.snapshot
    ) async -> Result<String, Error> {
        guard settings.canSendCaptures else {
            return .failure(MCPClientError.notConfigured(
                "Configure an Obsidian vault in Settings (direct write or MCP server)."
            ))
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(MCPClientError.notConfigured("Nothing to send"))
        }

        let payload = buildCapturePayload(
            trimmed: trimmed,
            projectName: projectName,
            projectPath: projectPath,
            settings: settings
        )

        if settings.canSendNotes,
           let projectName = payload.projectName,
           let projectPath = payload.projectPath
        {
            if case let .failure(error) = await ObsidianProjectLogIndex.ensure(
                projectName: projectName,
                projectPath: projectPath,
                settings: settings
            ) {
                return .failure(error)
            }
        }

        if settings.canSendViaDirectVault {
            switch sendViaDirectVault(payload: payload, settings: settings) {
            case let .success(path):
                return .success(path)
            case let .failure(error):
                if settings.canSendNotes {
                    break
                }
                return .failure(error)
            }
        }

        guard settings.canSendNotes else {
            return .failure(MCPClientError.notConfigured("Configure vault, Python, and server.py in Settings"))
        }

        return await sendViaMCP(payload: payload, settings: settings)
    }

    static func testConnection(
        settings: ObsidianMCPSettings = ObsidianMCPSettingsStore.shared.snapshot
    ) async -> Result<Int, Error> {
        if settings.canSendViaDirectVault {
            let folder = inboxFolderForDirectWrite(settings: settings)
            let vaultURL = URL(
                fileURLWithPath: ObsidianVaultPathValidator.normalizedPath(settings.vaultPath),
                isDirectory: true
            )
            let folderURL = vaultURL.appendingPathComponent(folder)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let entries = (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)) ?? []
                let noteCount = entries.count(where: { $0.hasSuffix(".md") })
                return .success(noteCount)
            }
            return .success(0)
        }

        guard settings.isEnabled else {
            return .failure(MCPClientError.notConfigured("Enable Obsidian MCP or configure direct vault write"))
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

    private struct CapturePayload {
        let notePath: String
        let noteContent: String
        let tags: [String]
        let appendToExisting: Bool
        let projectName: String?
        let projectPath: String?
    }

    private static func buildCapturePayload(
        trimmed: String,
        projectName: String?,
        projectPath: String?,
        settings: ObsidianMCPSettings
    ) -> CapturePayload {
        let title = ObsidianNotePathBuilder.title(from: trimmed)
        var tags = settings.defaultTags

        if let projectName, let projectPath {
            let projectTag = ObsidianNotePathBuilder.slugify(projectName)
            let structured = JadeProjectContextReader.loadStructured(projectPath: projectPath)
            let notePath = ObsidianNotePathBuilder.projectCapturePath(
                projectName: projectName,
                content: trimmed
            )
            let noteContent = JadeJourneyLogFormatter.captureNote(
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
            return CapturePayload(
                notePath: notePath,
                noteContent: noteContent,
                tags: tags,
                appendToExisting: false,
                projectName: projectName,
                projectPath: projectPath
            )
        }

        let notePath: String
        let appendToExisting: Bool
        switch settings.captureWriteMode {
        case .append:
            notePath = settings.normalizedDefaultCaptureNotePath.isEmpty
                ? ObsidianMCPSettings.defaultCaptureNotePath
                : settings.normalizedDefaultCaptureNotePath
            appendToExisting = true
        case .newFile:
            let folder = inboxFolderForDirectWrite(settings: settings)
            notePath = ObsidianNotePathBuilder.inboxNotePath(
                inboxFolder: folder,
                titleHint: title
            )
            appendToExisting = false
        }

        return CapturePayload(
            notePath: notePath,
            noteContent: trimmed,
            tags: tags,
            appendToExisting: appendToExisting,
            projectName: projectName,
            projectPath: nil
        )
    }

    private static func inboxFolderForDirectWrite(settings: ObsidianMCPSettings) -> String {
        let capturePath = settings.normalizedDefaultCaptureNotePath
        if capturePath.isEmpty {
            return settings.inboxFolder
        }
        let url = URL(fileURLWithPath: capturePath)
        let directory = url.deletingLastPathComponent().path
        if directory.isEmpty || directory == "." {
            return settings.inboxFolder
        }
        return directory
    }

    private static func sendViaDirectVault(
        payload: CapturePayload,
        settings: ObsidianMCPSettings
    ) -> Result<String, Error> {
        do {
            let body: String = if payload.appendToExisting {
                ObsidianVaultWriter.appendCaptureBlock(
                    body: payload.noteContent,
                    projectName: payload.projectName
                )
            } else {
                payload.noteContent
            }
            let savedPath = try ObsidianVaultWriter.writeNote(
                vaultPath: settings.vaultPath,
                relativePath: payload.notePath,
                content: body,
                append: payload.appendToExisting
            )
            return .success(savedPath)
        } catch {
            return .failure(error)
        }
    }

    private static func sendViaMCP(
        payload: CapturePayload,
        settings: ObsidianMCPSettings
    ) async -> Result<String, Error> {
        do {
            let configuration = MCPStdioSessionConfiguration(
                pythonPath: settings.pythonPath,
                serverScriptPath: settings.serverScriptPath,
                environment: settings.serverEnvironment
            )
            let encodedArguments = try JSONSerialization.data(withJSONObject: [
                "path": payload.notePath,
                "content": payload.noteContent,
                "title": ObsidianNotePathBuilder.title(from: payload.noteContent),
                "tags": payload.tags,
            ])
            let response = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: "create_note",
                encodedArguments: encodedArguments
            )
            let savedPath = response["path"] as? String ?? payload.notePath
            return .success(savedPath)
        } catch {
            return .failure(error)
        }
    }
}
