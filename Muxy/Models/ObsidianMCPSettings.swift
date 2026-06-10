import Foundation

struct ObsidianMCPSettings: Codable, Equatable {
    static let repositoryURL = "https://github.com/dot-RealityTest/obsidian-codex-mcp"
    static let defaultInboxFolder = "Jade/Inbox"
    static let defaultCaptureNotePath = "Jade/Inbox/capture.md"

    var isEnabled: Bool
    var vaultPath: String
    var pythonPath: String
    var serverScriptPath: String
    var readOnly: Bool
    var backupOnWrite: Bool
    var inboxFolder: String
    var defaultTags: [String]
    var preferDirectVaultWrite: Bool
    var defaultCaptureNotePath: String
    var captureWriteMode: ObsidianCaptureWriteMode

    static var defaults: ObsidianMCPSettings {
        ObsidianMCPSettings(
            isEnabled: false,
            vaultPath: "",
            pythonPath: "/usr/bin/python3",
            serverScriptPath: "",
            readOnly: false,
            backupOnWrite: true,
            inboxFolder: defaultInboxFolder,
            defaultTags: ["jade"],
            preferDirectVaultWrite: true,
            defaultCaptureNotePath: defaultCaptureNotePath,
            captureWriteMode: .append
        )
    }

    var isVaultConfigured: Bool {
        !vaultPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isServerConfigured: Bool {
        let python = pythonPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let script = serverScriptPath.trimmingCharacters(in: .whitespacesAndNewlines)
        return !python.isEmpty && !script.isEmpty
    }

    var canSendNotes: Bool {
        isEnabled && isVaultConfigured && isServerConfigured && !readOnly
    }

    var canSendViaDirectVault: Bool {
        guard preferDirectVaultWrite, !readOnly else { return false }
        guard isVaultConfigured else { return false }
        return ObsidianVaultPathValidator.validationMessage(for: vaultPath) == nil
    }

    var canSendCaptures: Bool {
        canSendViaDirectVault || canSendNotes
    }

    var normalizedDefaultCaptureNotePath: String {
        ObsidianVaultWriter.normalizedRelativePath(defaultCaptureNotePath)
    }

    var serverEnvironment: [String: String] {
        [
            "OBSIDIAN_VAULT_PATH": vaultPath,
            "OBSIDIAN_READ_ONLY": readOnly ? "true" : "false",
            "OBSIDIAN_BACKUP_ON_WRITE": backupOnWrite ? "true" : "false",
        ]
    }
}
