import Foundation

@MainActor
@Observable
final class ObsidianMCPSettingsStore {
    static let shared = ObsidianMCPSettingsStore()

    private enum Key {
        static let enabled = "mcp.obsidian.enabled"
        static let vaultPath = "mcp.obsidian.vaultPath"
        static let pythonPath = "mcp.obsidian.pythonPath"
        static let serverScriptPath = "mcp.obsidian.serverScriptPath"
        static let readOnly = "mcp.obsidian.readOnly"
        static let backupOnWrite = "mcp.obsidian.backupOnWrite"
        static let inboxFolder = "mcp.obsidian.inboxFolder"
        static let defaultTags = "mcp.obsidian.defaultTags"
        static let preferDirectVaultWrite = "mcp.obsidian.preferDirectVaultWrite"
        static let defaultCaptureNotePath = "mcp.obsidian.defaultCaptureNotePath"
        static let captureWriteMode = "mcp.obsidian.captureWriteMode"
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.enabled, fallback: false) }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    var vaultPath: String {
        get { UserDefaults.standard.string(forKey: Key.vaultPath) ?? "" }
        set {
            UserDefaults.standard.set(
                ObsidianVaultPathValidator.normalizedPath(newValue),
                forKey: Key.vaultPath
            )
        }
    }

    var pythonPath: String {
        get { UserDefaults.standard.string(forKey: Key.pythonPath) ?? ObsidianMCPSettings.defaults.pythonPath }
        set { UserDefaults.standard.set(newValue, forKey: Key.pythonPath) }
    }

    var serverScriptPath: String {
        get { UserDefaults.standard.string(forKey: Key.serverScriptPath) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: Key.serverScriptPath) }
    }

    var readOnly: Bool {
        get { UserDefaults.standard.bool(forKey: Key.readOnly, fallback: false) }
        set { UserDefaults.standard.set(newValue, forKey: Key.readOnly) }
    }

    var backupOnWrite: Bool {
        get { UserDefaults.standard.bool(forKey: Key.backupOnWrite, fallback: true) }
        set { UserDefaults.standard.set(newValue, forKey: Key.backupOnWrite) }
    }

    var inboxFolder: String {
        get {
            UserDefaults.standard.string(forKey: Key.inboxFolder)
                ?? ObsidianMCPSettings.defaultInboxFolder
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.inboxFolder) }
    }

    var defaultTags: String {
        get {
            UserDefaults.standard.string(forKey: Key.defaultTags)
                ?? ObsidianMCPSettings.defaults.defaultTags.joined(separator: ", ")
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.defaultTags) }
    }

    var preferDirectVaultWrite: Bool {
        get { UserDefaults.standard.bool(forKey: Key.preferDirectVaultWrite, fallback: true) }
        set { UserDefaults.standard.set(newValue, forKey: Key.preferDirectVaultWrite) }
    }

    var defaultCaptureNotePath: String {
        get {
            UserDefaults.standard.string(forKey: Key.defaultCaptureNotePath)
                ?? ObsidianMCPSettings.defaultCaptureNotePath
        }
        set {
            UserDefaults.standard.set(
                ObsidianVaultWriter.normalizedRelativePath(newValue),
                forKey: Key.defaultCaptureNotePath
            )
        }
    }

    var captureWriteMode: ObsidianCaptureWriteMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: Key.captureWriteMode),
                  let mode = ObsidianCaptureWriteMode(rawValue: raw)
            else { return .append }
            return mode
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Key.captureWriteMode) }
    }

    var snapshot: ObsidianMCPSettings {
        ObsidianMCPSettings(
            isEnabled: isEnabled,
            vaultPath: vaultPath,
            pythonPath: pythonPath,
            serverScriptPath: serverScriptPath,
            readOnly: readOnly,
            backupOnWrite: backupOnWrite,
            inboxFolder: inboxFolder,
            defaultTags: parsedDefaultTags,
            preferDirectVaultWrite: preferDirectVaultWrite,
            defaultCaptureNotePath: defaultCaptureNotePath,
            captureWriteMode: captureWriteMode
        )
    }

    var parsedDefaultTags: [String] {
        defaultTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func apply(_ settings: ObsidianMCPSettings) {
        isEnabled = settings.isEnabled
        vaultPath = settings.vaultPath
        pythonPath = settings.pythonPath
        serverScriptPath = settings.serverScriptPath
        readOnly = settings.readOnly
        backupOnWrite = settings.backupOnWrite
        inboxFolder = settings.inboxFolder
        defaultTags = settings.defaultTags.joined(separator: ", ")
        preferDirectVaultWrite = settings.preferDirectVaultWrite
        defaultCaptureNotePath = settings.defaultCaptureNotePath
        captureWriteMode = settings.captureWriteMode
    }
}
