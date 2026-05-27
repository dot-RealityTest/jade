import Foundation
import Testing

@testable import Muxy

@Suite("MuxyConfigTerminalRender")
struct MuxyConfigTerminalRenderTests {
    @Test("applyTerminalRenderDefaultsIfNeeded adds minimum-contrast and migrates block cursor once")
    @MainActor
    func appliesMinimumContrastAndMigratesBlockCursor() throws {
        let defaults = UserDefaults(suiteName: "MuxyConfigTerminalRenderTests")!
        defaults.removePersistentDomain(forName: "MuxyConfigTerminalRenderTests")

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let configURL = tempDir.appendingPathComponent("ghostty.conf")
        try "cursor-style = block\n".write(to: configURL, atomically: true, encoding: .utf8)

        let config = MuxyConfig(ghosttyConfigURL: configURL, userDefaults: defaults)

        let changed = config.applyTerminalRenderDefaultsIfNeeded()
        let content = try String(contentsOf: configURL, encoding: .utf8)

        #expect(changed)
        #expect(content.contains("minimum-contrast = 1.1"))
        #expect(content.contains("cursor-style = bar"))
        #expect(defaults.bool(forKey: "terminalRenderDefaultsV1"))

        let changedAgain = config.applyTerminalRenderDefaultsIfNeeded()
        #expect(!changedAgain)
    }
}
