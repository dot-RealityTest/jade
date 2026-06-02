import Foundation
import Testing

@testable import Muxy

@Suite("Capture Path Integration")
@MainActor
struct CapturePathIntegrationTests {
    @Test("journey step to session note uses project-session-log frontmatter")
    func journeyStepToSessionNote() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Muxy")
        let structured = JadeProjectContextReader.loadStructured(projectPath: root.path)
        let proposal = JourneyStepProposal(
            title: "Verify capture path",
            summary: "Run dogfood automation",
            why: "Scope audit chose Rich Input + Obsidian.",
            sourceFile: "todo.md",
            risk: .low
        )

        let note = JadeJourneyLogFormatter.sessionNote(
            input: JadeJourneyLogFormatter.SessionNoteInput(
                outcome: .completed,
                proposal: proposal,
                projectName: "Muxy",
                projectPath: root.path,
                context: structured.paths,
                structured: structured,
                overriddenBlocker: false
            )
        )

        #expect(note.contains("type: project-session-log"))
        #expect(note.contains("Verify capture path"))
        #expect(note.hasPrefix("---"))
    }

    @Test("Rich Input content formats as project capture note")
    func richInputFormatsAsProjectCapture() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Muxy")
        let structured = JadeProjectContextReader.loadStructured(projectPath: root.path)
        let path = ObsidianNotePathBuilder.projectCapturePath(
            projectName: "Muxy",
            content: "Palette smoke test"
        )

        #expect(path.contains("Jade/Logs/muxy/notes/"))
        #expect(path.hasSuffix(".md"))

        let note = JadeJourneyLogFormatter.captureNote(
            input: JadeJourneyLogFormatter.CaptureNoteInput(
                content: "Palette smoke test",
                projectName: "Muxy",
                projectPath: root.path,
                structured: structured
            )
        )

        #expect(note.contains("type: project-capture"))
        #expect(note.contains("Palette smoke test"))
    }
}

@Suite("Capture Path Live Obsidian")
struct CapturePathLiveObsidianTests {
    private static var liveSettings: ObsidianMCPSettings? {
        guard ProcessInfo.processInfo.environment["JADE_DOGFOOD_OBSIDIAN"] == "1" else { return nil }
        let vault = ProcessInfo.processInfo.environment["OBSIDIAN_VAULT_PATH"]
            ?? "/Users/kika_hub/_KIKA_MAIN/Kika's_Obsidian"
        let python = ProcessInfo.processInfo.environment["OBSIDIAN_PYTHON_PATH"]
            ?? "/Users/kika_hub/Projects/obsidian-mcp/.venv/bin/python"
        let server = ProcessInfo.processInfo.environment["OBSIDIAN_SERVER_SCRIPT"]
            ?? "/Users/kika_hub/Projects/obsidian-mcp/server.py"
        guard FileManager.default.fileExists(atPath: vault),
              FileManager.default.isExecutableFile(atPath: python),
              FileManager.default.fileExists(atPath: server)
        else { return nil }

        var settings = ObsidianMCPSettings.defaults
        settings.isEnabled = true
        settings.vaultPath = vault
        settings.pythonPath = python
        settings.serverScriptPath = server
        settings.readOnly = false
        settings.inboxFolder = "Jade/Inbox"
        return settings
    }

    @Test("send capture note to vault when dogfood env is set")
    func sendCaptureNoteToVault() async throws {
        guard let settings = Self.liveSettings else { return }

        let marker = "jade-dogfood-\(UUID().uuidString.prefix(8))"
        let result = await ObsidianSendService.send(
            content: marker,
            projectName: "Muxy",
            projectPath: FileManager.default.currentDirectoryPath,
            settings: settings
        )

        switch result {
        case let .success(path):
            let vaultRoot = URL(fileURLWithPath: settings.vaultPath, isDirectory: true)
            let noteURL = vaultRoot.appendingPathComponent(path)
            #expect(FileManager.default.fileExists(atPath: noteURL.path))
            let body = try String(contentsOf: noteURL, encoding: .utf8)
            #expect(body.contains(marker))
            try FileManager.default.removeItem(at: noteURL)
        case let .failure(error):
            Issue.record("Obsidian send failed: \(error.localizedDescription)")
            #expect(Bool(false))
        }
    }
}
