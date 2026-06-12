import Foundation

struct ObsidianCaptureSettings: Codable, Equatable {
    static let defaultInboxFolder = "Jade/Inbox"
    static let defaultCaptureNotePath = "Jade/Inbox/capture.md"

    var vaultPath: String
    var inboxFolder: String
    var defaultCaptureNotePath: String
    var captureWriteMode: ObsidianCaptureWriteMode

    static var defaults: ObsidianCaptureSettings {
        ObsidianCaptureSettings(
            vaultPath: "",
            inboxFolder: defaultInboxFolder,
            defaultCaptureNotePath: defaultCaptureNotePath,
            captureWriteMode: .append
        )
    }

    var isVaultConfigured: Bool {
        !vaultPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSendCaptures: Bool {
        ObsidianVaultPathValidator.validationMessage(for: vaultPath) == nil
    }

    var normalizedDefaultCaptureNotePath: String {
        ObsidianVaultWriter.normalizedRelativePath(defaultCaptureNotePath)
    }
}

enum ObsidianCaptureError: LocalizedError {
    case notConfigured(String)

    var errorDescription: String? {
        switch self {
        case let .notConfigured(message):
            message
        }
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
        guard !normalized.isEmpty else { return "Choose a logs folder." }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: normalized, isDirectory: &isDirectory) else {
            return "Logs folder does not exist."
        }
        guard isDirectory.boolValue else { return "Logs destination must be a folder." }
        return nil
    }
}
