import Foundation

@MainActor
@Observable
final class ObsidianCaptureSettingsStore {
    static let shared = ObsidianCaptureSettingsStore()

    private enum Key {
        static let vaultPath = "mcp.obsidian.vaultPath"
        static let inboxFolder = "mcp.obsidian.inboxFolder"
        static let defaultCaptureNotePath = "mcp.obsidian.defaultCaptureNotePath"
        static let captureWriteMode = "mcp.obsidian.captureWriteMode"
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

    var inboxFolder: String {
        get {
            UserDefaults.standard.string(forKey: Key.inboxFolder)
                ?? ObsidianCaptureSettings.defaultInboxFolder
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.inboxFolder) }
    }

    var defaultCaptureNotePath: String {
        get {
            UserDefaults.standard.string(forKey: Key.defaultCaptureNotePath)
                ?? ObsidianCaptureSettings.defaultCaptureNotePath
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

    var snapshot: ObsidianCaptureSettings {
        ObsidianCaptureSettings(
            vaultPath: vaultPath,
            inboxFolder: inboxFolder,
            defaultCaptureNotePath: defaultCaptureNotePath,
            captureWriteMode: captureWriteMode
        )
    }

    func apply(_ settings: ObsidianCaptureSettings) {
        vaultPath = settings.vaultPath
        inboxFolder = settings.inboxFolder
        defaultCaptureNotePath = settings.defaultCaptureNotePath
        captureWriteMode = settings.captureWriteMode
    }
}
