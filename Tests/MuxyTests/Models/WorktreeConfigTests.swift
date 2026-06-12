import Foundation
import Testing

@testable import Muxy

@Suite("WorktreeConfig")
struct WorktreeConfigTests {
    private func makeProjectDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("worktree-config-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func writeConfig(in projectDir: URL, folder: String, command: String) throws {
        let configDir = projectDir.appendingPathComponent(folder)
        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let json = #"{"setup": ["\#(command)"]}"#
        try Data(json.utf8).write(to: configDir.appendingPathComponent("worktree.json"))
    }

    @Test("loads from .jade/worktree.json")
    func loadsFromJadeFolder() throws {
        let dir = try makeProjectDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try writeConfig(in: dir, folder: ".jade", command: "npm install")

        let config = WorktreeConfig.load(fromProjectPath: dir.path)

        #expect(config?.setup.map(\.command) == ["npm install"])
    }

    @Test("falls back to legacy .muxy/worktree.json")
    func fallsBackToLegacyFolder() throws {
        let dir = try makeProjectDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try writeConfig(in: dir, folder: ".muxy", command: "bundle install")

        let config = WorktreeConfig.load(fromProjectPath: dir.path)

        #expect(config?.setup.map(\.command) == ["bundle install"])
    }

    @Test(".jade wins when both folders exist")
    func jadeWinsOverLegacy() throws {
        let dir = try makeProjectDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        try writeConfig(in: dir, folder: ".jade", command: "new")
        try writeConfig(in: dir, folder: ".muxy", command: "old")

        let config = WorktreeConfig.load(fromProjectPath: dir.path)

        #expect(config?.setup.map(\.command) == ["new"])
    }

    @Test("layout discovery merges both folders with .jade priority")
    func layoutDiscoveryMergesFolders() throws {
        let dir = try makeProjectDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let jadeLayouts = dir.appendingPathComponent(".jade/layouts")
        let muxyLayouts = dir.appendingPathComponent(".muxy/layouts")
        try FileManager.default.createDirectory(at: jadeLayouts, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: muxyLayouts, withIntermediateDirectories: true)
        try Data("panes: []".utf8).write(to: jadeLayouts.appendingPathComponent("dev.yaml"))
        try Data("panes: []".utf8).write(to: muxyLayouts.appendingPathComponent("dev.yaml"))
        try Data("panes: []".utf8).write(to: muxyLayouts.appendingPathComponent("legacy.yaml"))

        let descriptors = LayoutConfig.discover(projectPath: dir.path)

        #expect(descriptors.map(\.name) == ["dev", "legacy"])
        #expect(descriptors.first { $0.name == "dev" }?.url.path.contains(".jade") == true)
    }
}
