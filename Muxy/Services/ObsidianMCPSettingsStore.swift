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

    var snapshot: ObsidianMCPSettings {
        ObsidianMCPSettings(
            isEnabled: isEnabled,
            vaultPath: vaultPath,
            pythonPath: pythonPath,
            serverScriptPath: serverScriptPath,
            readOnly: readOnly,
            backupOnWrite: backupOnWrite,
            inboxFolder: inboxFolder,
            defaultTags: parsedDefaultTags
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
    }
}
