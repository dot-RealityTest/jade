import Foundation

@MainActor
struct ObsidianSendService {
    static func send(
        content: String,
        projectName: String?,
        projectPath: String? = nil,
        settings: ObsidianCaptureSettings = ObsidianCaptureSettingsStore.shared.snapshot
    ) -> Result<String, Error> {
        guard settings.canSendCaptures else {
            return .failure(ObsidianCaptureError.notConfigured(
                "Choose a logs folder in Settings first."
            ))
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .failure(ObsidianCaptureError.notConfigured("Nothing to send"))
        }

        let payload = buildCapturePayload(
            trimmed: trimmed,
            projectName: projectName,
            projectPath: projectPath,
            settings: settings
        )

        if let projectName = payload.projectName, let projectPath = payload.projectPath {
            if case let .failure(error) = ObsidianProjectLogIndex.ensure(
                projectName: projectName,
                projectPath: projectPath,
                settings: settings
            ) {
                return .failure(error)
            }
        }

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

    static func testConnection(
        settings: ObsidianCaptureSettings = ObsidianCaptureSettingsStore.shared.snapshot
    ) -> Result<Int, Error> {
        if let message = ObsidianVaultPathValidator.validationMessage(for: settings.vaultPath) {
            return .failure(ObsidianCaptureError.notConfigured(message))
        }
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

    private struct CapturePayload {
        let notePath: String
        let noteContent: String
        let appendToExisting: Bool
        let projectName: String?
        let projectPath: String?
    }

    private static func buildCapturePayload(
        trimmed: String,
        projectName: String?,
        projectPath: String?,
        settings: ObsidianCaptureSettings
    ) -> CapturePayload {
        let title = ObsidianNotePathBuilder.title(from: trimmed)

        if let projectName, let projectPath {
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
            return CapturePayload(
                notePath: notePath,
                noteContent: noteContent,
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
                ? ObsidianCaptureSettings.defaultCaptureNotePath
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
            appendToExisting: appendToExisting,
            projectName: projectName,
            projectPath: nil
        )
    }

    private static func inboxFolderForDirectWrite(settings: ObsidianCaptureSettings) -> String {
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
}
