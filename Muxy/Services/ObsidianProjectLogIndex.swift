import Foundation

enum ObsidianProjectLogIndex {
    static func vaultRelativePath(projectName: String) -> String {
        ObsidianNotePathBuilder.projectLogIndexPath(projectName: projectName)
    }

    static func exists(projectName: String, settings: ObsidianCaptureSettings) -> Bool {
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
        settings: ObsidianCaptureSettings
    ) -> Result<Void, Error> {
        guard settings.canSendCaptures else {
            return .success(())
        }

        if exists(projectName: projectName, settings: settings) {
            return .success(())
        }

        let indexPath = vaultRelativePath(projectName: projectName)
        let structured = JadeProjectContextReader.loadStructured(projectPath: projectPath)
        let content = JadeJourneyLogFormatter.projectLogIndex(
            projectName: projectName,
            projectPath: projectPath,
            structured: structured
        )

        do {
            _ = try ObsidianVaultWriter.writeNote(
                vaultPath: settings.vaultPath,
                relativePath: indexPath,
                content: content,
                append: false
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
