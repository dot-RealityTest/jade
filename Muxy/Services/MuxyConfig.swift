import Foundation
import os

private let logger = Logger(subsystem: "app.muxy", category: "MuxyConfig")

@MainActor @Observable
final class MuxyConfig {
    static let shared = MuxyConfig()

    let ghosttyConfigURL: URL

    private static let ghosttyConfigFilename = "ghostty.conf"
    private static let terminalRenderDefaultsMigrationKey = "terminalRenderDefaultsV1"
    private static let systemGhosttyConfigPath = NSHomeDirectory() + "/.config/ghostty/config"
    private let userDefaults: UserDefaults

    private init(ghosttyConfigURL: URL, userDefaults: UserDefaults, seedFromSystem: Bool) {
        self.ghosttyConfigURL = ghosttyConfigURL
        self.userDefaults = userDefaults
        if seedFromSystem {
            seedFromSystemGhosttyIfNeeded()
        }
    }

    private convenience init() {
        let dir = MuxyFileStorage.appSupportDirectory()
        self.init(
            ghosttyConfigURL: dir.appendingPathComponent(Self.ghosttyConfigFilename),
            userDefaults: .standard,
            seedFromSystem: true
        )
    }

    convenience init(ghosttyConfigURL: URL, userDefaults: UserDefaults) {
        self.init(ghosttyConfigURL: ghosttyConfigURL, userDefaults: userDefaults, seedFromSystem: false)
    }

    var ghosttyConfigPath: String {
        ghosttyConfigURL.path
    }

    func readGhosttyConfig() -> String {
        (try? String(contentsOf: ghosttyConfigURL, encoding: .utf8)) ?? ""
    }

    func writeGhosttyConfig(_ content: String) throws {
        let data = Data(content.utf8)
        try data.write(to: ghosttyConfigURL, options: .atomic)
        Self.restrictFilePermissions(ghosttyConfigURL)
    }

    func updateConfigValue(_ key: String, value: String) {
        let entry = "\(key) = \(value)"
        var content = readGhosttyConfig()
        var lines = content.components(separatedBy: "\n")

        if let index = findConfigLineIndex(for: key, in: lines) {
            lines[index] = entry
        } else {
            lines.insert(entry, at: 0)
        }

        content = lines.joined(separator: "\n")
        do {
            try writeGhosttyConfig(content)
        } catch {
            logger.error("Failed to write config: \(error)")
        }
    }

    func configValue(for key: String) -> String? {
        let lines = readGhosttyConfig().components(separatedBy: .newlines)
        guard let index = findConfigLineIndex(for: key, in: lines) else { return nil }
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        let afterKey = trimmed.dropFirst(key.count).trimmingCharacters(in: .whitespaces)
        return afterKey.dropFirst().trimmingCharacters(in: .whitespaces)
    }

    @discardableResult
    func applyTerminalRenderDefaultsIfNeeded() -> Bool {
        var changed = false

        if configValue(for: "minimum-contrast") == nil {
            updateConfigValue("minimum-contrast", value: "1.1")
            changed = true
        }

        let migrationKey = Self.terminalRenderDefaultsMigrationKey
        guard !userDefaults.bool(forKey: migrationKey) else { return changed }

        if configValue(for: "cursor-style") == "block" {
            updateConfigValue("cursor-style", value: "bar")
            changed = true
        }

        userDefaults.set(true, forKey: migrationKey)
        return changed
    }

    private func findConfigLineIndex(for key: String, in lines: [String]) -> Int? {
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(key) else { continue }
            let afterKey = trimmed.dropFirst(key.count).trimmingCharacters(in: .whitespaces)
            guard afterKey.hasPrefix("=") else { continue }
            return i
        }
        return nil
    }

    private func seedFromSystemGhosttyIfNeeded() {
        guard !FileManager.default.fileExists(atPath: ghosttyConfigURL.path) else { return }

        guard FileManager.default.fileExists(atPath: Self.systemGhosttyConfigPath),
              let systemContent = try? String(contentsOfFile: Self.systemGhosttyConfigPath, encoding: .utf8)
        else {
            try? writeGhosttyConfig("")
            return
        }

        try? writeGhosttyConfig(systemContent)
    }

    private static func restrictFilePermissions(_ url: URL) {
        try? FileManager.default.setAttributes(
            [.posixPermissions: FilePermissions.privateFile],
            ofItemAtPath: url.path
        )
    }
}
