import Foundation
import Testing

@testable import Muxy

@Suite("Obsidian Vault Writer")
struct ObsidianVaultWriterTests {
    @Test("writes and appends capture note inside vault")
    func writesAndAppendsCaptureNote() throws {
        let vault = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: vault) }

        let relative = "Jade/Inbox/capture.md"
        let first = try ObsidianVaultWriter.writeNote(
            vaultPath: vault.path,
            relativePath: relative,
            content: "First capture",
            append: false
        )
        #expect(first == relative)

        let block = ObsidianVaultWriter.appendCaptureBlock(body: "Second capture", projectName: "Muxy")
        let second = try ObsidianVaultWriter.writeNote(
            vaultPath: vault.path,
            relativePath: relative,
            content: block,
            append: true
        )
        #expect(second == relative)

        let fileURL = vault.appendingPathComponent(relative)
        let body = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(body.contains("First capture"))
        #expect(body.contains("Second capture"))
        #expect(body.contains("Project: Muxy"))
    }

    @Test("rejects paths that escape vault")
    func rejectsPathTraversal() {
        let vault = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: vault) }

        #expect(throws: ObsidianVaultWriterError.self) {
            _ = try ObsidianVaultWriter.resolvedFileURL(
                vaultPath: vault.path,
                relativePath: "../outside.md"
            )
        }
    }

    @Test("direct send writes inbox capture without MCP")
    func directSendWritesInboxCapture() async throws {
        let vault = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: vault) }

        var settings = ObsidianMCPSettings.defaults
        settings.vaultPath = vault.path
        settings.preferDirectVaultWrite = true
        settings.defaultCaptureNotePath = "Jade/Inbox/capture.md"
        settings.captureWriteMode = .append
        #expect(settings.canSendViaDirectVault)
        #expect(settings.canSendCaptures)

        let marker = "direct-vault-\(UUID().uuidString.prefix(8))"
        let result = await ObsidianSendService.send(
            content: marker,
            projectName: nil,
            projectPath: nil,
            settings: settings
        )

        switch result {
        case let .success(path):
            #expect(path == "Jade/Inbox/capture.md")
            let noteURL = vault.appendingPathComponent(path)
            let body = try String(contentsOf: noteURL, encoding: .utf8)
            #expect(body.contains(marker))
        case let .failure(error):
            Issue.record("Direct send failed: \(error.localizedDescription)")
            #expect(Bool(false))
        }
    }
}
