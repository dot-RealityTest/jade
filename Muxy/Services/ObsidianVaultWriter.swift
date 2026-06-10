import Foundation

enum ObsidianVaultWriterError: LocalizedError {
    case invalidVault
    case invalidRelativePath
    case pathEscapesVault
    case readOnly
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidVault:
            "Configure a valid Obsidian vault folder in Settings."
        case .invalidRelativePath:
            "Capture note path must be a relative .md path inside the vault."
        case .pathEscapesVault:
            "Capture path must stay inside the vault folder."
        case .readOnly:
            "Obsidian capture is read-only. Turn off Read Only in Settings."
        case let .writeFailed(message):
            "Could not write to Obsidian vault: \(message)"
        }
    }
}

enum ObsidianVaultWriter {
    static func writeNote(
        vaultPath: String,
        relativePath: String,
        content: String,
        append: Bool
    ) throws -> String {
        let normalizedRelative = normalizedRelativePath(relativePath)
        let fileURL = try resolvedFileURL(vaultPath: vaultPath, relativePath: normalizedRelative)
        let parent = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)

        if append, FileManager.default.fileExists(atPath: fileURL.path) {
            let existing = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
            let separator = existing.isEmpty ? "" : "\n\n---\n\n"
            let combined = existing + separator + content
            try writeString(combined, to: fileURL)
        } else {
            try writeString(content, to: fileURL)
        }

        return normalizedRelative
    }

    static func resolvedFileURL(vaultPath: String, relativePath: String) throws -> URL {
        if ObsidianVaultPathValidator.validationMessage(for: vaultPath) != nil {
            throw ObsidianVaultWriterError.invalidVault
        }
        let normalizedRelative = normalizedRelativePath(relativePath)
        guard normalizedRelative.hasSuffix(".md") else {
            throw ObsidianVaultWriterError.invalidRelativePath
        }

        let vaultURL = URL(
            fileURLWithPath: ObsidianVaultPathValidator.normalizedPath(vaultPath),
            isDirectory: true
        )
        let targetURL = vaultURL.appendingPathComponent(normalizedRelative)
        let vaultRoot = vaultURL.resolvingSymlinksInPath().standardizedFileURL
        let resolvedTarget = targetURL.resolvingSymlinksInPath().standardizedFileURL
        let vaultRootPath = directoryPathWithoutTrailingSlash(vaultRoot)
        let targetPath = resolvedTarget.path(percentEncoded: false)
        let isInsideVault = targetPath == vaultRootPath || targetPath.hasPrefix(vaultRootPath + "/")
        guard isInsideVault else {
            throw ObsidianVaultWriterError.pathEscapesVault
        }
        return targetURL
    }

    private static func directoryPathWithoutTrailingSlash(_ url: URL) -> String {
        var path = url.path(percentEncoded: false)
        while path.count > 1, path.hasSuffix("/") {
            path.removeLast()
        }
        return path
    }

    static func normalizedRelativePath(_ raw: String) -> String {
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "\\", with: "/")
        let components = trimmed.split(separator: "/").map(String.init)
        guard !components.contains("..") else { return "" }
        return components.joined(separator: "/")
    }

    static func appendCaptureBlock(body: String, projectName: String?) -> String {
        let timestamp = captureTimestamp()
        var lines = ["**Captured** \(timestamp)"]
        if let projectName {
            let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                lines.append("Project: \(trimmed)")
            }
        }
        lines.append("")
        lines.append(body.trimmingCharacters(in: .whitespacesAndNewlines))
        return lines.joined(separator: "\n")
    }

    private static func captureTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    private static func writeString(_ text: String, to url: URL) throws {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ObsidianVaultWriterError.writeFailed(error.localizedDescription)
        }
    }
}
